#pragma once
#include "Frame.h"
#include <vector>
#include <panda/refcnt.h>
#include <panda/string.h>
#include <panda/error.h>

namespace panda { namespace protocol { namespace websocket {

using panda::string;

struct Message : virtual panda::Refcnt {
    std::vector<string> payload;

    Message (size_t max_size) : _max_size(max_size), _state(State::PENDING), _payload_length(0), _frame_count(0), _deflated(false) {}

    Opcode   opcode         () const { return _opcode; }
    bool     is_control     () const { return FrameHeader::is_control_opcode(_opcode); }
    uint16_t close_code     () const { return _close_code; }
    string   close_message  () const { return _close_message; }
    size_t   payload_length () const { return _payload_length; }
    uint32_t frame_count    () const { return _frame_count; }

    const ErrorCode& error () const { return _error; }

    bool add_frame (const Frame& frame);

    size_t max_size () const         { return _max_size; }
    void   max_size (size_t newsize) { _max_size = newsize; }

    bool deflated () const { return _deflated; }
    void deflated (bool v) { _deflated = v; }
private:
    enum class State { PENDING, DONE };

    ErrorCode _error;
    size_t    _max_size;
    State     _state;
    Opcode    _opcode;
    uint16_t  _close_code;
    string    _close_message;
    size_t    _payload_length;
    uint32_t  _frame_count;
    bool      _deflated;
};

using MessageSP = panda::iptr<Message>;

}}}
