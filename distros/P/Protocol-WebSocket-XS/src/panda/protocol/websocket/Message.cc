#include "Message.h"
#include <cassert>

namespace panda { namespace protocol { namespace websocket {

bool Message::add_frame (const Frame& frame) {
    assert(_state != State::DONE);

    if (frame.error) {
        error = frame.error;
        _state = State::DONE;
        return true;
    }

    if (!frame_count++) {
        _opcode = frame.opcode();
        if (_opcode == Opcode::CLOSE) {
            _close_code    = frame.close_code();
            _close_message = frame.close_message();
        }
    }

    if (_max_size && _payload_length + frame.payload_length() > _max_size) {
        error = errc::max_message_size;
        _state = State::DONE;
        return true;
    }

    for (const auto& s : frame.payload) {
        _payload_length += s.length();
        payload.push_back(s);
    }

    if (frame.final()) _state = State::DONE;

    return _state == State::DONE;
}

}}}
