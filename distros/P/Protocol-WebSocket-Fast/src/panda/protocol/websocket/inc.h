#pragma once
#include <cstdint>

namespace panda { namespace protocol { namespace websocket {

enum class Opcode : uint8_t {
    CONTINUE = 0x00,
    TEXT     = 0x01,
    BINARY   = 0x02,
    CLOSE    = 0x08,
    PING     = 0x09,
    PONG     = 0x0A,
};

namespace CloseCode {

enum CloseCode : uint16_t {
    NO_ERROR = 0,

    DONE             = 1000,
    AWAY             = 1001,
    PROTOCOL_ERROR   = 1002,
    INVALID_DATA     = 1003,
    UNKNOWN          = 1005, // NOT FOR SENDING
    ABNORMALLY       = 1006, // NOT FOR SENDING
    INVALID_TEXT     = 1007,
    BAD_REQUEST      = 1008,
    MAX_SIZE         = 1009,
    EXTENSION_NEEDED = 1010, // FOR SENDING BY CLIENT ONLY
    INTERNAL_ERROR   = 1011,
    TLS              = 1015 // NOT FOR SENDING

};

inline bool is_sending_forbidden(uint16_t code) {
    return (code < DONE || code == 1004 || code == UNKNOWN || code == ABNORMALLY || (code > INTERNAL_ERROR && code < 3000));
}

}

}}}
