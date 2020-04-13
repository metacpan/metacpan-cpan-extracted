#pragma once
#include "Frame.h"
#include <vector>
#include <panda/refcnt.h>
#include <panda/string.h>
#include <panda/error.h>

namespace panda { namespace protocol { namespace websocket {

using panda::string;

struct Message : virtual panda::Refcnt {
    ErrorCode           error;
    std::vector<string> payload;
    uint32_t            frame_count;

    Message (size_t max_size) : frame_count(0), _max_size(max_size), _state(State::PENDING), _payload_length(0) {}

    Opcode   opcode         () const { return _opcode; }
    bool     is_control     () const { return FrameHeader::is_control_opcode(_opcode); }
    uint16_t close_code     () const { return _close_code; }
    string   close_message  () const { return _close_message; }
    size_t   payload_length () const { return _payload_length; }

    bool add_frame (const Frame& frame);

    size_t max_size () const         { return _max_size; }
    void   max_size (size_t newsize) { _max_size = newsize; }

private:
    enum class State { PENDING, DONE };

    size_t   _max_size;
    State    _state;
    Opcode   _opcode;
    uint16_t _close_code;
    string   _close_message;
    size_t   _payload_length;

};

using MessageSP = panda::iptr<Message>;

}}}
