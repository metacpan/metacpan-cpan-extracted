#pragma once
#include <panda/log.h>
#include <system_error>
#include <panda/exception.h>

namespace panda { namespace protocol { namespace websocket {

extern const std::error_category& error_categoty;
extern log::Module pwslog;

enum class errc {
    garbage_after_connect = 1,
    unsupported_version,
    response_code_101,
    connection_mustbe_upgrade,
    upgrade_mustbe_websocket,
    sec_accept_missing,
    method_mustbe_get,
    http_1_1_required,
    body_prohibited,
    invalid_opcode,
    control_fragmented,
    control_payload_too_big,
    not_masked,
    max_frame_size,
    max_message_size,
    close_frame_invalid_data,
    initial_continue,
    fragment_no_continue,
    deflate_negotiation_failed,
    control_frame_compression,
    inflate_error,
};

struct ErrorCategoty : std::error_category {
    const char* name () const noexcept override;
    std::string message (int ev) const override;
};

inline std::error_code make_error_code (errc err) noexcept {
    return std::error_code(int(err), error_categoty);
}

struct Error : panda::exception {
    using exception::exception;
};

}}}

namespace std {
    template <> struct is_error_code_enum<panda::protocol::websocket::errc> : std::true_type {};
}
