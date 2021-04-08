#include "Parser.h"
#include <cstdlib>
#include <cassert>
#include <iostream>

namespace panda { namespace protocol { namespace websocket {

using std::cout;
using std::endl;

void Parser::configure (const Config& cfg) {
    _max_frame_size     = cfg.max_frame_size;
    _max_message_size   = cfg.max_message_size;
    _max_handshake_size = cfg.max_handshake_size;
    _check_utf8         = cfg.check_utf8;

    if (!_flags[ESTABLISHED]) {
        _deflate_cfg = cfg.deflate;
        if (_deflate_cfg) _deflate_cfg->max_message_size = _max_message_size;
    }

    if (_frame) _frame->max_size(_max_frame_size);
    if (_message) _message->max_size(_max_message_size);
    _message_frame.max_size(_max_frame_size);
}

void Parser::reset () {
    _buffer.clear();
    _flags.reset();
    _frame = NULL;
    _frame_count = 0;
    _message = NULL;
    _message_frame.reset();
    if (_deflate_ext) _deflate_ext->reset();
    _suggested_close_code = 0;
}

bool Parser::_parse_frame (Frame& frame) {
    if (!frame.parse(_buffer)) {
        _buffer.clear();
        return false;
    }

    auto _err = [&]() -> bool {
        _buffer.clear();
        _frame_count = 0;
        _flags.reset(RECV_FRAME);
        _flags.reset(RECV_INFLATE);
        _utf8_checker.reset();
        if      (frame.error() & errc::invalid_utf8)   _suggested_close_code = CloseCode::INVALID_TEXT;
        else if (frame.error() & errc::max_frame_size) _suggested_close_code = CloseCode::MAX_SIZE;
        else                                           _suggested_close_code = CloseCode::PROTOCOL_ERROR;

        return true;
    };

    auto _seterr = [&](const std::error_code& ec) -> bool {
        frame.error(ec);
        return _err();
    };

    if (frame.error()) return _err();

    if (frame.is_control()) { // control frames can't be fragmented, no need to increment frame count
        if (!_frame_count) _flags.reset(RECV_FRAME); // do not reset state if control frame arrives in the middle of message
        if (frame.opcode() == Opcode::CLOSE) {
            _buffer.clear();
            _flags.set(RECV_CLOSED);
            if (frame.close_code() == CloseCode::UNKNOWN) _suggested_close_code = CloseCode::DONE;
            else                                          _suggested_close_code = frame.close_code();

            if (_check_utf8 && frame.close_message()) {
                _utf8_checker.reset();
                if (!_utf8_checker.write(frame.close_message()) || !_utf8_checker.finish()) return _seterr(errc::invalid_utf8);
            }
        }
        return true;
    }

    if (_frame_count == 0) {
        if (frame.opcode() == Opcode::CONTINUE) return _seterr(errc::initial_continue);
        if (frame.rsv1()) {
            if (_deflate_ext) _flags.set(RECV_INFLATE);
            else return _seterr(errc::unexpected_rsv);
        }
        if (frame.rsv2() | frame.rsv3()) return _seterr(errc::unexpected_rsv);
    }
    else {
        if (frame.opcode() != Opcode::CONTINUE) return _seterr(errc::fragment_no_continue);
    }

    if (_flags[RECV_INFLATE]) {
        _deflate_ext->uncompress(frame);
        if (frame.error()) return _err();
    }

    if (_check_utf8) {
        if (_frame_count == 0 && frame.opcode() == Opcode::TEXT) _flags.set(RECV_TEXT);
        if (_flags[RECV_TEXT] && !_utf8_checker.write(frame.payload)) return _seterr(errc::invalid_utf8);
        if (frame.final()) {
            if (!_utf8_checker.finish()) return _seterr(errc::invalid_utf8);
            _flags.reset(RECV_TEXT);
        }
    }

    if (frame.final()) {
        _flags.reset(RECV_FRAME);
        _flags.reset(RECV_INFLATE);
        _frame_count = 0;
    }
    else ++_frame_count;

    return true;
}

FrameSP Parser::_get_frame () {
    if (!_flags[ESTABLISHED]) throw Error("not established");
    if (_flags[RECV_MESSAGE]) throw Error("message is being parsed");
    if (_flags[RECV_CLOSED]) { _buffer.clear(); return nullptr; }
    if (!_buffer) return nullptr;

    _flags.set(RECV_FRAME);
    if (!_frame) _frame = new Frame(_recv_mask_required, _max_frame_size);

    if (!_parse_frame(*_frame)) return nullptr;

    FrameSP ret = std::move(_frame);
    _frame = nullptr;
    return ret;
}

MessageSP Parser::_get_message () {
    if (!_flags[ESTABLISHED]) throw Error("not established");
    if (_flags[RECV_FRAME]) throw Error("frame mode active");
    if (_flags[RECV_CLOSED]) { _buffer.clear(); return nullptr; }
    if (!_buffer) return nullptr;

    _flags.set(RECV_MESSAGE);
    if (!_message) _message = new Message(_max_message_size);

    while (1) {
        if (!_parse_frame(_message_frame)) return nullptr;

        // control frame arrived in the middle of fragmented message - wrap in new message and return (state remains MESSAGE)
        // because user can only switch to getting frames after receiving non-control message
        if (!_message_frame.error() && _message_frame.is_control() && _message->frame_count()) {
            auto cntl_msg = new Message(_max_message_size);
            bool done = cntl_msg->add_frame(_message_frame);
            assert(done);
            _message_frame.reset();
            return cntl_msg;
        }

        bool done = _message->add_frame(_message_frame);
        _message_frame.reset();

        if (done) break;
        if (!_buffer) return nullptr;
    }

    if (_message->error()) {
        if (_message->error() & errc::max_message_size) _suggested_close_code = CloseCode::MAX_SIZE;
    }

    _flags.reset(RECV_MESSAGE);
    _flags.reset(RECV_INFLATE);
    MessageSP ret = std::move(_message);
    _message = nullptr;
    return ret;
}

FrameHeader Parser::_prepare_control_header (Opcode opcode) {
    _check_send();
    if (opcode == Opcode::CLOSE) {
        _flags.set(SEND_CLOSED);
        _flags.reset(SEND_FRAME);
    }
    return FrameHeader(opcode, true, 0, 0, 0, !_recv_mask_required, _recv_mask_required ? 0 : (uint32_t)std::rand());
}

FrameHeader Parser::_prepare_frame_header (IsFinal final) {
    if (!_flags[SEND_FRAME]) throw Error("can't send frame: message has not been started");

    if (FrameHeader::is_control_opcode(_send_opcode)) {
        if (final == IsFinal::NO) throw Error("control frame must be final");
        return _prepare_control_header(_send_opcode);
    }

    Opcode opcode;
    bool rsv1;

    if (_sent_frame_count) {
        opcode = Opcode::CONTINUE;
        rsv1 = false;
    }
    else {
        opcode = _send_opcode;
        rsv1 = _flags[SEND_DEFLATE];
    }

    if (final == IsFinal::YES) {
        _sent_frame_count = 0;
        _flags.reset(SEND_FRAME);
        _flags.reset(SEND_DEFLATE);
    }
    else ++_sent_frame_count;

    return FrameHeader(opcode, (bool)final, rsv1, 0, 0, !_recv_mask_required, _recv_mask_required ? 0 : (uint32_t)std::rand());
}

}}}
