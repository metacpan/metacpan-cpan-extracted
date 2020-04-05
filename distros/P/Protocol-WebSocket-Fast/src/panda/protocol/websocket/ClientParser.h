#pragma once
#include "Parser.h"
#include "ConnectRequest.h"
#include "ConnectResponse.h"
#include <panda/string.h>
#include <panda/protocol/http/ResponseParser.h>

namespace panda { namespace protocol { namespace websocket {

using panda::string;

struct ClientParser : Parser {

    ClientParser () : Parser(false), _connect_response_parser() {}

    string connect_request (const ConnectRequestSP& req);

    ConnectResponseSP connect (string& buf);

    virtual void reset ();

    virtual ~ClientParser () {}

private:
    static const int CONNECTION_REQUESTED       = LAST_FLAG + 1;
    static const int CONNECTION_RESPONSE_PARSED = CONNECTION_REQUESTED + 1;

    ConnectRequestSP     _connect_request;
    ConnectResponseSP    _connect_response;
    http::ResponseParser _connect_response_parser;
};

}}}
