#pragma once
#include "inc.h"
#include <panda/string.h>
#include <panda/iterator.h>

namespace panda { namespace protocol { namespace websocket {

using panda::string;
using panda::IteratorPair;

struct FrameHeader {
    Opcode   opcode;
    bool     fin;
    bool     rsv1;
    bool     rsv2;
    bool     rsv3;
    bool     has_mask;
    uint32_t mask;
    uint64_t length;

    FrameHeader () : mask(0), length(0), _state(State::FIRST), _len16(0) {}

    FrameHeader (Opcode opcode, bool final, bool rsv1, bool rsv2, bool rsv3, bool has_mask, uint32_t mask) :
        opcode(opcode), fin(final), rsv1(rsv1), rsv2(rsv2), rsv3(rsv3), has_mask(has_mask), mask(mask) {}

    bool is_control () const { return is_control_opcode(opcode); }

    bool   parse   (string& buf);
    string compile (size_t plen) const;

    void reset () {
        mask   = 0;
        length = 0;
        _state = State::FIRST;
        _len16 = 0;
    }

    static bool   parse_close_payload   (const string& payload, uint16_t& code, string& message);
    static string compile_close_payload (uint16_t code, const string& message);

    static bool is_control_opcode (Opcode opcode) { return opcode >= Opcode::CLOSE; }


private:
    enum class State { FIRST, SECOND, LENGTH, MASK, DONE };
    State    _state;
    uint8_t  _slen;
    uint16_t _len16;

    string _compile_header (size_t plen);

};

}}}
