#pragma once
#include "error.h"
#include "MessageParser.h"

namespace panda { namespace protocol { namespace http {

struct ResponseParser : MessageParser {
    struct Result {
        ResponseSP      response;
        size_t          position;
        State           state;
        std::error_code error;
    };

    ResponseParser ();
    ResponseParser (ResponseParser&&) = default;

    const RequestSP& context_request () const { return _context_request; }

    void set_context_request (const RequestSP& request) {
        if (_context_request) throw ParserError("can't set another context request until response is done");
        _context_request = request;
    }

    Result parse (const string& buffer);

    Result parse_shift (string& s) {
        auto result = parse(s);
        s.offset(result.position);
        result.position = 0;
        return result;
    }

    Result eof ();

    void reset () { _reset(false); }

protected:
    bool on_headers    ();
    bool on_empty_body ();

private:
    RequestSP _context_request;

    void ensure_response_created () {
        if (!response) {
            if (!_context_request) throw ParserError("Cannot create response as there are no corresponding request");
            response = _context_request->new_response();
            message  = response;
        }
    }

    void _reset (bool keep_context);

    void parse_cookie (const string&);
};

}}}
