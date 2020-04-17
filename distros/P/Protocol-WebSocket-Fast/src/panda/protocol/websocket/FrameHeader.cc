#include "FrameHeader.h"
#include "utils.h"
#include <cassert>
#include <cstring>
#include <iostream>
#include <panda/endian.h>

namespace panda { namespace protocol { namespace websocket {

using std::cout;
using std::endl;

static const int MAX_SIZE = 14;  // 2 bytes required + 8-byte length + 4-byte mask

#pragma pack(push,1)
    struct BinaryFirst {
        uint8_t opcode : 4;
        bool    rsv3   : 1;
        bool    rsv2   : 1;
        bool    rsv1   : 1;
        bool    fin    : 1;
    };
    struct BinarySecond {
        uint8_t slen : 7;
        bool    mask : 1;
    };
#pragma pack(pop)

bool FrameHeader::parse (string& buf) {
    assert(_state != State::DONE);

    auto data = buf.data();
    auto end  = data + buf.length();

    if (_state == State::FIRST) {
        if (data == end) return false;
        auto first = *((BinaryFirst*)data++);
        fin    = first.fin;
        rsv1   = first.rsv1;
        rsv2   = first.rsv2;
        rsv3   = first.rsv3;
        opcode = (Opcode)first.opcode;
        _state = State::SECOND;
    }

    if (_state == State::SECOND) {
        if (data == end) return false;
        auto second = *((BinarySecond*)data++);
        has_mask = second.mask;
        _slen    = second.slen;
        _state = State::LENGTH;
        //cout << "FrameHeader[parse]: HASMASK=" << has_mask << ", SLEN=" << (int)_slen << endl;
    }

    if (_state == State::LENGTH) {
        if (_slen < 126) {
            length = _slen;
            _state = State::MASK;
            //cout << "FrameHeader[parse]: LENGTH(7)=" << length << endl;
        }
        else if (data == end) return false;
        else if (_slen == 126) {
            if (!parse_binary_number(_len16, data, end - data)) return false;
            length = be2h16(_len16);
            _state = State::MASK;
            //cout << "FrameHeader[parse]: LENGTH(16)=" << length << endl;
        }
        else { // 127
            if (!parse_binary_number(length, data, end - data)) return false;
            length = be2h64(length);
            _state = State::MASK;
            //cout << "FrameHeader[parse]: LENGTH(64)=" << length << endl;
        }
    }

    if (_state == State::MASK) {
        if (!has_mask) _state = State::DONE;
        else if (data == end) return false;
        else {
            if (!parse_binary_number(mask, data, end - data)) return false;
            _state = State::DONE;
            //cout << "FrameHeader[parse]: MASK=" << mask << endl;
        }
    }

    if (data == end) buf.clear();       // no extra data after the end of frame
    else buf.offset(data - buf.data()); // leave rest in buffer

    return true;
}

string FrameHeader::compile (size_t plen) const {
    string ret(MAX_SIZE);
    char* ptr = ret.buf();
    const char*const begin = ptr;

    *((BinaryFirst*)ptr++) = BinaryFirst{(uint8_t)opcode, rsv3, rsv2, rsv1, fin};

    if (plen < 126) {
        *((BinarySecond*)ptr++) = BinarySecond{(uint8_t)plen, has_mask};
    } else if (plen < 65536) {
        *((BinarySecond*)ptr++) = BinarySecond{126, has_mask};
        *((uint16_t*)ptr) = h2be16(plen);
        ptr += sizeof(uint16_t);
    } else {
        *((BinarySecond*)ptr++) = BinarySecond{127, has_mask};
        *((uint64_t*)ptr) = h2be64(plen);
        ptr += sizeof(uint64_t);
    }

    if (has_mask) {
        *((uint32_t*)ptr) = mask;
        ptr += sizeof(uint32_t);
    }

    ret.length(ptr - begin);
    return ret;
}

bool FrameHeader::parse_close_payload (const string& payload, uint16_t& code, string& message) {
    if (!payload) code = (uint16_t)CloseCode::UNKNOWN;
    else if (payload.length() < sizeof(code)) {
        code = (uint16_t)CloseCode::UNKNOWN;
        return false;
    }
    auto ptr = payload.data();
    code = be2h16(*((uint16_t*)ptr));
    message = payload.substr(sizeof(code));
    // check for invalid close codes
    return !CloseCode::is_sending_forbidden(code);
}

string FrameHeader::compile_close_payload (uint16_t code, const string& message) {
    size_t sz = sizeof(code) + message.length();
    string ret(sz);
    char* buf = ret.buf();
    *((uint16_t*)buf) = h2be16(code);
    buf += sizeof(code);
    if (message.length()) std::memcpy(buf, message.data(), message.length());
    ret.length(sz);
    return ret;
}

}}}
