#pragma once
#include "Error.h"
#include "Frame.h"
#include "Message.h"
#include "DeflateExt.h"
#include "Utf8Checker.h"
#include <deque>
#include <bitset>
#include <iterator>
#include <panda/refcnt.h>
#include <panda/string.h>
#include <panda/optional.h>
#include <panda/protocol/http/MessageParser.h>

namespace panda { namespace protocol { namespace websocket {

using panda::string;
using panda::IteratorPair;

enum class DeflateFlag { NO, DEFAULT, YES };

struct Parser : virtual panda::Refcnt {
    // include child classes to solve cross-dependencies without moving one-liners to *.cc files (to avoid performance loses)
    #include "Parser-FrameSender.h"
    #include "Parser-MessageBuilder.h"
    #include "Parser-MessageIterator.h"

    using DeflateConfig = DeflateExt::Config;

    struct Config {
        Config () {}
        size_t max_frame_size           = 0;
        size_t max_message_size         = 0;
        size_t max_handshake_size       = http::SIZE_UNLIMITED;
        bool   check_utf8               = false;
        optional<DeflateConfig> deflate = DeflateConfig();
    };

    void configure (const Config& cfg);

    size_t max_frame_size     () const { return _max_frame_size; }
    size_t max_message_size   () const { return _max_message_size; }
    size_t max_handshake_size () const { return _max_handshake_size; }

    bool established () const { return _flags[ESTABLISHED]; }
    bool recv_closed () const { return _flags[RECV_CLOSED]; }
    bool send_closed () const { return _flags[SEND_CLOSED]; }

    FrameIteratorPair get_frames () {
        return FrameIteratorPair(FrameIterator(this, _get_frame()), FrameIterator(this, NULL));
    }

    MessageIteratorPair get_messages () {
        return MessageIteratorPair(MessageIterator(this, _get_message()), MessageIterator(this, NULL));
    }

    FrameIteratorPair get_frames (string&& buf) {
        if (_buffer) _buffer += std::move(buf); // user has not iterated previous call to get_frames till the end or remainder after handshake on client side
        else         _buffer = std::move(buf);
        return get_frames();
    }

    FrameIteratorPair get_frames (const string& buf) {
        if (_buffer) _buffer += buf;
        else         _buffer = buf;
        return get_frames();
    }

    MessageIteratorPair get_messages (string&& buf) {
        if (_buffer) _buffer += std::move(buf);
        else         _buffer = std::move(buf);
        return get_messages();
    }

    MessageIteratorPair get_messages (const string& buf) {
        if (_buffer) _buffer += buf;
        else         _buffer = buf;
        return get_messages();
    }

    FrameSender start_message (Opcode opcode = Opcode::BINARY, DeflateFlag deflate = DeflateFlag::NO) {
        _check_send();
        if (_flags[SEND_FRAME]) throw Error("can't start message: previous message wasn't finished");
        _flags.set(SEND_FRAME);
        _send_opcode = opcode;
        if (_deflate_ext && deflate != DeflateFlag::NO) _flags.set(SEND_DEFLATE);
        return FrameSender(*this);
    }

    FrameSender start_message (DeflateFlag deflate) { return start_message(Opcode::BINARY, deflate); }

    string send_frame (IsFinal final = IsFinal::NO) {
        bool deflate = _flags[SEND_DEFLATE];
        auto header = _prepare_frame_header(final);
        if (final == IsFinal::YES && deflate) _deflate_ext->reset_tx();
        return Frame::compile(header);
    }

    string send_frame (string_view payload, IsFinal final = IsFinal::NO) {
        bool deflate = _flags[SEND_DEFLATE];
        auto header = _prepare_frame_header(final);
        return deflate ? Frame::compile(header, _deflate_ext->compress(payload, final)) :
                         Frame::compile(header, payload);
    }

    template <typename It, typename T = decltype(*std::declval<It>()), typename = std::enable_if_t<std::is_convertible<T, string_view>::value>>
    string send_frame (It&& payload_begin, It&& payload_end, IsFinal final = IsFinal::NO) {
        bool deflate = _flags[SEND_DEFLATE];
        auto header = _prepare_frame_header(final);
        return deflate ? Frame::compile(header, _deflate_ext->compress(payload_begin, payload_end, final)) :
                         Frame::compile(header, payload_begin, payload_end);
    }

    MessageBuilder message () { return MessageBuilder(*this); }

    string send_control (Opcode opcode) {
        return Frame::compile(_prepare_control_header(opcode));
    }

    string send_control (Opcode opcode, string_view payload) {
        if (payload.length() > Frame::MAX_CONTROL_PAYLOAD) {
            panda_log_critical("control frame payload is too long");
            payload = payload.substr(0, Frame::MAX_CONTROL_PAYLOAD);
        }
        auto header = _prepare_control_header(opcode);
        return Frame::compile(header, payload);
    }

    string send_ping  ()                    { return send_control(Opcode::PING); }
    string send_ping  (string_view payload) { return send_control(Opcode::PING, payload); }
    string send_pong  ()                    { return send_control(Opcode::PONG); }
    string send_pong  (string_view payload) { return send_control(Opcode::PONG, payload); }
    string send_close ()                    { return send_control(Opcode::CLOSE); }

    string send_close (uint16_t code, string_view close_payload = {}) {
        string payload = FrameHeader::compile_close_payload(code, close_payload);
        return send_control(Opcode::CLOSE, payload);
    }

    uint16_t suggested_close_code () const { return _suggested_close_code; }

    virtual void reset ();

    bool is_deflate_active () const { return (bool)_deflate_ext; }

    const optional<DeflateConfig>& deflate_config () const { return _deflate_cfg; }

    optional<DeflateConfig> effective_deflate_config () const {
        if (!_deflate_ext) return {};
        return _deflate_ext->effective_config();
    }

    void no_deflate () {
        if (!_flags[ESTABLISHED]) _deflate_cfg.reset();
    }

    virtual ~Parser () {}

protected:
    using DeflateExtPtr = std::unique_ptr<DeflateExt>;

    static const int ESTABLISHED  = 1; // connection has been established
    static const int RECV_FRAME   = 2; // frame mode receive
    static const int RECV_MESSAGE = 3; // message mode receive
    static const int RECV_INFLATE = 4; // receiving compressed message
    static const int RECV_TEXT    = 5; // receiving text message
    static const int RECV_CLOSED  = 6; // no more messages from peer (close packet received)
    static const int SEND_FRAME   = 7; // outgoing message started
    static const int SEND_DEFLATE = 8; // sending compressed message
    static const int SEND_CLOSED  = 9; // no more messages from user (close packet sent)
    static const int LAST_FLAG    = SEND_CLOSED;

    size_t                  _max_frame_size;
    size_t                  _max_message_size;
    size_t                  _max_handshake_size;
    bool                    _check_utf8;
    std::bitset<32>         _flags = 0;
    string                  _buffer;
    optional<DeflateConfig> _deflate_cfg;
    DeflateExtPtr           _deflate_ext;

    Parser (bool recv_mask_required, Config cfg = Config()) : _recv_mask_required(recv_mask_required), _message_frame(recv_mask_required, cfg.max_frame_size) {
        configure(cfg);
    }

private:
    bool        _recv_mask_required;
    FrameSP     _frame;                    // current frame being received (frame mode)
    int         _frame_count = 0;          // frame count for current message being received
    MessageSP   _message;                  // current message being received (message mode)
    Frame       _message_frame;            // current frame being received (message mode)
    int         _sent_frame_count = 0;     // frame count for current message being sent (frame mode)
    Opcode      _send_opcode;              // opcode for first frame to be sent (frame mode)
    uint16_t    _suggested_close_code = 0; // suggested close code to send to peer after error or receiving close frame from peer
    Utf8Checker _utf8_checker;

    std::deque<string> _simple_payload_tmp;

    FrameSP   _get_frame   ();
    MessageSP _get_message ();
    bool      _parse_frame (Frame&);

    void _check_send () const {
        if (!_flags[ESTABLISHED]) throw Error("not established");
        if (_flags[SEND_CLOSED]) throw Error("close sent, can't send anymore");
    }

    FrameHeader _prepare_control_header (Opcode);
    FrameHeader _prepare_frame_header   (IsFinal);

    friend struct FrameSender;
    friend struct MessageBuilder;
};

using FrameIteratorPair   = Parser::FrameIteratorPair;
using FrameIterator       = Parser::FrameIterator;
using MessageIteratorPair = Parser::MessageIteratorPair;
using MessageIterator     = Parser::MessageIterator;
using FrameSender         = Parser::FrameSender;
using MessageBuilder      = Parser::MessageBuilder;
using ParserSP            = iptr<Parser>;

}}}
