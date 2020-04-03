#include "Parser.h"
#include <cstdlib>
#include <cassert>
#include <iostream>

namespace panda { namespace protocol { namespace websocket {

using std::cout;
using std::endl;

void Parser::reset () {
    _buffer.clear();
    _flags.reset();
    _frame = NULL;
    _frame_count = 0;
    _message = NULL;
    _message_frame.reset();
    if (_deflate_ext) _deflate_ext->reset();
}

FrameSP Parser::_get_frame () {
    if (!_flags[ESTABLISHED]) throw Error("not established");
    if (_flags[RECV_MESSAGE]) throw Error("message is being parsed");
    if (_flags[RECV_CLOSED]) { _buffer.clear(); return NULL; }
    if (!_buffer) return NULL;

    _flags.set(RECV_FRAME);
    if (!_frame) _frame = new Frame(_recv_mask_required, _max_frame_size);

    if (!_frame->parse(_buffer)) {
        _buffer.clear();
        return NULL;
    }
    _frame->check(_frame_count);

    if (_frame_count == 0 && _frame->rsv1() && _deflate_ext) _flags.set(RECV_INFLATE);
    if (_flags[RECV_INFLATE]) _deflate_ext->uncompress(*_frame);

    if (_frame->error) {
        _buffer.clear();
        _frame_count = 0;
        _flags.reset(RECV_INFLATE);
    }
    else if (_frame->is_control()) { // control frames can't be fragmented, no need to increment frame count
        if (!_frame_count) _flags.reset(RECV_FRAME); // do not reset state if control frame arrives in the middle of message
        if (_frame->opcode() == Opcode::CLOSE) {
            _buffer.clear();
            _flags.set(RECV_CLOSED);
        }
    }
    else if (_frame->final()) {
        _flags.reset(RECV_FRAME);
        _flags.reset(RECV_INFLATE);
        _frame_count = 0;
    }
    else ++_frame_count;

    FrameSP ret(_frame);
    _frame = NULL;
    return ret;
}

MessageSP Parser::_get_message () {
    if (!_flags[ESTABLISHED]) throw Error("not established");
    if (_flags[RECV_FRAME]) throw Error("frame mode active");
    if (_flags[RECV_CLOSED]) { _buffer.clear(); return NULL; }
    if (!_buffer) return NULL;

    _flags.set(RECV_MESSAGE);
    if (!_message) _message = new Message(_max_message_size);

    while (1) {
        if (!_message_frame.parse(_buffer)) {
            _buffer.clear();
            return NULL;
        }

        // control frame arrived in the middle of fragmented message - wrap in new message and return (state remains MESSAGE)
        // because user can only switch to getting frames after receiving non-control message
        if (!_message_frame.error && _message_frame.is_control()) {
            if (_message_frame.opcode() == Opcode::CLOSE) {
                _buffer.clear();
                _flags.set(RECV_CLOSED);
            }
            if (_message->frame_count) {
                auto cntl_msg = new Message(_max_message_size);
                bool done = cntl_msg->add_frame(_message_frame);
                assert(done);
                _message_frame.reset();
                return cntl_msg;
            }
        }

        _message_frame.check(_message->frame_count);

        if (_message->frame_count == 0 && _message_frame.rsv1() && _deflate_ext) _flags.set(RECV_INFLATE);
        if (_flags[RECV_INFLATE]) _deflate_ext->uncompress(_message_frame);

        bool done = _message->add_frame(_message_frame);
        _message_frame.reset();

        if (done) break;
        if (!_buffer) return NULL;
    }

    if (_message->error) _buffer.clear();

    _flags.reset(RECV_MESSAGE);
    _flags.reset(RECV_INFLATE);
    MessageSP ret(_message);
    _message = NULL;
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

FrameHeader Parser::_prepare_frame_header (bool final) {
    if (!_flags[SEND_FRAME]) throw Error("can't send frame: message has not been started");

    if (FrameHeader::is_control_opcode(_send_opcode)) {
        if (!final) throw Error("control frame must be final");
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

    if (final) {
        _sent_frame_count = 0;
        _flags.reset(SEND_FRAME);
        _flags.reset(SEND_DEFLATE);
    }
    else ++_sent_frame_count;

    return FrameHeader(opcode, final, rsv1, 0, 0, !_recv_mask_required, _recv_mask_required ? 0 : (uint32_t)std::rand());
}

}}}
