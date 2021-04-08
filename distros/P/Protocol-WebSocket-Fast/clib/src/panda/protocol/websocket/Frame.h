#pragma once
#include "inc.h"
#include "utils.h"
#include "Error.h"
#include "FrameHeader.h"
#include <vector>
#include <cassert>
#include <panda/refcnt.h>
#include <panda/string.h>
#include <panda/memory.h>
#include <panda/error.h>

namespace panda { namespace protocol { namespace websocket {

using panda::string;

enum class IsFinal { NO = 0, YES };

struct Frame : virtual panda::Refcnt, AllocatedObject<Frame> {
    static constexpr int MAX_CONTROL_PAYLOAD = 125;
    static constexpr int MAX_CLOSE_PAYLOAD   = MAX_CONTROL_PAYLOAD - 2;

    std::vector<string> payload;

    Frame (bool mask_required, size_t max_size) : _mask_required(mask_required), _max_size(max_size), _state(State::HEADER) {}

    bool     is_control     () const { return _header.is_control(); }
    Opcode   opcode         () const { return _header.opcode; }
    bool     final          () const { return _header.fin; }
    bool     rsv1           () const { return _header.rsv1; }
    bool     rsv2           () const { return _header.rsv2; }
    bool     rsv3           () const { return _header.rsv3; }
    size_t   payload_length () const { return _header.length; }
    uint16_t close_code     () const { return _close_code; }
    string   close_message  () const { return _close_message; }

    const ErrorCode& error () const             { return _error; }
    void             error (const ErrorCode& e) { _error = e; }

    size_t max_size () const         { return _max_size; }
    void   max_size (size_t newsize) { _max_size = newsize; }

    bool parse (string& buf);

    void reset () {
        _state = State::HEADER;
        _header.reset();
        _error.clear();
        payload.clear();
    }

    static string compile (const FrameHeader& header) {
        return header.compile(0);
    }

    static string compile (const FrameHeader& header, string_view payload) {
        size_t plen = payload.length();
        auto ret = header.compile(plen);
        if (!plen) return ret;

        auto buf = ret.buf() + ret.length();
        if (header.has_mask) crypt_mask(payload.data(), buf, plen, header.mask, 0);
        else                 memcpy(buf, payload.data(), plen);
        ret.length(ret.length() + plen);

        return ret;
    }

    template <class It>
    static string compile (const FrameHeader& header, It&& payload_begin, It&& payload_end) {
        size_t plen = 0;
        for (auto it = payload_begin; it != payload_end; ++it) plen += it->length();

        auto ret = header.compile(plen);
        if (!plen) return ret;

        plen = 0;
        auto buf = ret.buf() + ret.length();
        for (auto it = payload_begin; it != payload_end; ++it) {
            auto clen = it->length();
            if (header.has_mask) {
                crypt_mask(it->data(), buf, clen, header.mask, plen);
            }
            else {
                memcpy(buf, it->data(), clen);
            }
            buf += clen;
            plen += clen; // mask offset
        }
        ret.length(ret.length() + plen);

        return ret;
    }

private:
    enum class State { HEADER, PAYLOAD, DONE };
    bool        _mask_required;
    size_t      _max_size;
    State       _state;
    FrameHeader _header;
    uint64_t    _payload_bytes_left;
    uint16_t    _close_code;
    string      _close_message;
    ErrorCode   _error;
};

using FrameSP = panda::iptr<Frame>;

}}}
