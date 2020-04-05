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

struct Frame : virtual panda::Refcnt, AllocatedObject<Frame> {
    static constexpr int MAX_CONTROL_PAYLOAD = 125;
    static constexpr int MAX_CLOSE_PAYLOAD   = MAX_CONTROL_PAYLOAD - 2;

    ErrorCode           error;
    std::vector<string> payload;

    Frame (bool mask_required, size_t max_size) : _mask_required(mask_required), _max_size(max_size), _state(State::HEADER) {}

    bool     is_control     () const { return _header.is_control(); }
    Opcode   opcode         () const { return _header.opcode; }
    bool     final          () const { return _header.fin; }
    bool     rsv1           () const { return _header.rsv1; }
    size_t   payload_length () const { return _header.length; }
    uint16_t close_code     () const { return _close_code; }
    string   close_message  () const { return _close_message; }

    bool parse (string& buf);

    void check (bool fragment_in_message) {
        assert(_state == State::DONE);
        if (is_control() || error) return;
        if (!fragment_in_message) {
            if (opcode() == Opcode::CONTINUE) error = errc::initial_continue;
        }
        else if (opcode() != Opcode::CONTINUE) error = errc::fragment_no_continue;
    }

    void reset () {
        _state = State::HEADER;
        _header.reset();
        error.clear();
        payload.clear();
    }

    static string compile (const FrameHeader& header) {
        return header.compile(0);
    }

    static string compile (const FrameHeader& header, string& payload) {
        size_t plen = payload.length();
        if (header.has_mask && plen) crypt_mask(payload.buf(), plen, header.mask, 0);
        return header.compile(plen);
    }

    template <class It>
    static string compile (const FrameHeader& header, It payload_begin, It payload_end) {
        size_t plen = 0;
        auto payload = IteratorPair<It>(payload_begin, payload_end);
        if (header.has_mask) for (string& str : payload) {
            auto slen = str.length();
            crypt_mask(str.buf(), slen, header.mask, plen);
            plen += slen;
        }
        else for (string& str : payload) plen += str.length();

        return header.compile(plen);
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

};

using FrameSP = panda::iptr<Frame>;

}}}
