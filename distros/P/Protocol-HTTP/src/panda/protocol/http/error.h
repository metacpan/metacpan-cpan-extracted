#pragma once
#include <system_error>
#include <panda/exception.h>

namespace panda { namespace protocol { namespace http {

enum class errc {
    lexical_error = 1,
    multiple_content_length,
    headers_too_large,
    body_too_large,
    unexpected_body,
    unexpected_eof,
    unexpected_continue,
    unsupported_transfer_encoding,
    unsupported_compression,
    uncompression_failure,
    corrupted_cookie_jar,
};

struct ErrorCategory : std::error_category {
    const char* name () const noexcept override;
    std::string message (int condition) const noexcept override;
};
extern const ErrorCategory error_category;

struct ParserError : panda::exception {
    using exception::exception;
};

inline std::error_code make_error_code (errc code) { return std::error_code((int)code, error_category); }

}}}

namespace std {
    template <>
    struct is_error_code_enum<panda::protocol::http::errc> : true_type {};
}
