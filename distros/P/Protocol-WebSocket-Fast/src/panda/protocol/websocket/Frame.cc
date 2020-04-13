#include "Frame.h"
#include <cassert>
#include <iostream>

namespace panda { namespace protocol { namespace websocket {

using std::cout;
using std::endl;

// returns true if frame is done
bool Frame::parse (string& buf) {
    assert(_state != State::DONE);

    auto _err = [&](const std::error_code& ec) -> bool {
        error = ec;
        _state = State::DONE;
        return true;
    };

    if (_state == State::HEADER) {
        if (!_header.parse(buf)) return false;

        if (opcode() > Opcode::PONG || (opcode() > Opcode::BINARY && opcode() < Opcode::CLOSE)) return _err(errc::invalid_opcode);

        if (is_control()) {
            if (!final())                             return _err(errc::control_fragmented);
            if (_header.length > MAX_CONTROL_PAYLOAD) return _err(errc::control_payload_too_big);
            if (_header.rsv1)                         return _err(errc::control_frame_compression);
        }

        if (!_header.has_mask && _mask_required && _header.length) return _err(errc::not_masked);
        if (_max_size && _header.length > _max_size)               return _err(errc::max_frame_size);

        _state = _header.length ? State::PAYLOAD : State::DONE;
        _payload_bytes_left = _header.length;
    }

    if (_state == State::PAYLOAD) {
        if (!buf) return false;
        auto buflen = buf.length();
        //cout << "Frame[parse]: have buflen=" << buflen << ", payloadleft=" << _payload_bytes_left << endl;
        if (buflen >= _payload_bytes_left) { // last needed buffer
            if (_header.has_mask) crypt_mask(buf.shared_buf(), _payload_bytes_left, _header.mask, _header.length - _payload_bytes_left);
            if (buflen == _payload_bytes_left) { // payload is the whole buf
                payload.push_back(buf);
                buf.clear();
            }
            else { // have extra data after payload
                payload.push_back(buf.substr(0, _payload_bytes_left));
                buf.offset(_payload_bytes_left); // leave the rest in buf
            }
            _state = State::DONE;
        }
        else { // not last buffer
            if (_header.has_mask) crypt_mask(buf.shared_buf(), buflen, _header.mask, _header.length - _payload_bytes_left);
            _payload_bytes_left -= buflen;
            payload.push_back(buf);
            return false;
        }
    }

    if (opcode() == Opcode::CLOSE) {
        //cout << "HERE1\n";
        if (!_header.length) _close_code = (uint16_t)CloseCode::UNKNOWN;
        else {
            string str;
            if (payload.size() == 1) str = payload[0];
            else {
                str.reserve(_header.length);
                for (const auto& s : payload) str += s;
            }

            if (!FrameHeader::parse_close_payload(str, _close_code, _close_message)) return _err(errc::close_frame_invalid_data);

            payload.clear();
            payload.push_back(_close_message);
            _header.length = _close_message.length();
        }
        //cout << "Frame[parse]: CLOSE CODE=" << _close_code << " MSG=" << _close_message << endl;
    }

    return true;
}

}}}
