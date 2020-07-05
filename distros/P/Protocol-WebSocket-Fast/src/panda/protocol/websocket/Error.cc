#include "Error.h"
#include <map>
#include <panda/log.h>

namespace panda { namespace protocol { namespace websocket {

log::Module panda_log_module("Protocol::WebSocket", log::WARNING);

const std::error_category& error_category = ErrorCategory();

const char* ErrorCategory::name () const noexcept { return "protocol-websocket"; }

std::string ErrorCategory::message (int ev) const {
    switch (errc(ev)) {
        case errc::garbage_after_connect      : return "garbage found after http request";
        case errc::response_code_101          : return "handshake response code must be 101";
        case errc::unsupported_version        : return "client's Sec-WebSocket-Version is not supported";
        case errc::connection_mustbe_upgrade  : return "Connection must be 'Upgrade'";
        case errc::upgrade_mustbe_websocket   : return "Upgrade must be 'websocket'";
        case errc::sec_accept_missing         : return "Sec-WebSocket-Accept missing or invalid";
        case errc::method_mustbe_get          : return "method must be GET";
        case errc::http_1_1_required          : return "HTTP/1.1 or higher required";
        case errc::body_prohibited            : return "body must not present";
        case errc::invalid_opcode             : return "invalid opcode received";
        case errc::control_fragmented         : return "control frame can't be fragmented";
        case errc::control_payload_too_big    : return "control frame payload is too big";
        case errc::not_masked                 : return "frame is not masked";
        case errc::max_frame_size             : return "max frame size exceeded";
        case errc::close_frame_invalid_data   : return "control frame CLOSE contains invalid data";
        case errc::initial_continue           : return "initial frame can't have opcode CONTINUE";
        case errc::fragment_no_continue       : return "fragment frame must have opcode CONTINUE";
        case errc::max_message_size           : return "max message size exceeded";
        case errc::deflate_negotiation_failed : return "deflate parameters negotiation error";
        case errc::control_frame_compression  : return "compression of control frames is not allowed";
        case errc::inflate_error              : return "zlib::inflate error";
        case errc::unexpected_rsv             : return "RSV is set but no extension defining RSV meaning has been negotiated";
        case errc::invalid_utf8               : return "invalid utf8 sequence";
    }
    return "unknown error";
}

}}}
