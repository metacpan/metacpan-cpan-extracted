#pragma once
#include "Parser.h"
#include "ConnectRequest.h"
#include "ConnectResponse.h"
#include <panda/string.h>
#include <panda/optional.h>
#include <panda/protocol/http/RequestParser.h>

namespace panda { namespace protocol { namespace websocket {

using panda::string;

struct ServerParser : Parser {
    ServerParser (const Parser::Config& cfg = {});

    bool accept_parsed () const { return _flags[ACCEPT_PARSED]; }
    bool accepted      () const { return _flags[ACCEPTED]; }

    ConnectRequestSP accept (const string& buf);

    string accept_error    ();
    string accept_error    (http::Response* res);
    string accept_response (ConnectResponse* res);

    string accept_response () {
        ConnectResponse res;
        return accept_response(&res);
    }

    virtual void reset ();

    virtual ~ServerParser ();

private:
    static const int ACCEPT_PARSED = LAST_FLAG + 1;
    static const int ACCEPTED      = ACCEPT_PARSED + 1;

    http::RequestParser _connect_parser;
    ConnectRequestSP    _connect_request;
};

}}}
