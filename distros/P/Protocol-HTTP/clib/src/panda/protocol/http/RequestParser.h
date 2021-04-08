#pragma once
#include "error.h"
#include "MessageParser.h"

namespace panda { namespace protocol { namespace http {

struct IRequestFactory {
    virtual RequestSP new_request () = 0;
};

struct RequestParser : MessageParser {
    struct Result {
        RequestSP       request;
        size_t          position;
        State           state;
        std::error_code error;
    };

    struct IFactory {
        virtual RequestSP new_request () = 0;
    };

    RequestParser (IFactory* = nullptr);
    RequestParser (RequestParser&&) = default;

    Result parse (const string&);

    Result parse_shift (string& s) {
        auto result = parse(s);
        s.offset(result.position);
        result.position = 0;
        return result;
    }

    void reset ();
protected:
    bool on_headers    ();
    bool on_empty_body ();

private:
    IFactory* factory;

    RequestSP new_request () const { return factory ? factory->new_request() : make_iptr<Request>(); }

    void parse_cookie (const string&);
};

}}}
