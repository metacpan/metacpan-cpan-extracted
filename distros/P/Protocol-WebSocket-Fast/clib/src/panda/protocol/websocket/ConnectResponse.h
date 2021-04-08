#pragma once
#include "HeaderValueParamsParser.h"
#include <panda/refcnt.h>
#include <panda/error.h>
#include <panda/protocol/http/Response.h>

namespace panda { namespace protocol { namespace websocket {

struct ConnectResponse : http::Response {
    ConnectResponse () : _ws_extensions_set(false) {}

    virtual void process_headers ();

    const string&    ws_accept_key () const { return _ws_accept_key; }
    const string&    ws_version    () const { return _ws_version; }
    const string&    ws_protocol   () const { return _ws_protocol; }
    const ErrorCode& error         () const { return _error; }

    const HeaderValues& ws_extensions     () const { return _ws_extensions; }
    bool                ws_extensions_set () const { return _ws_extensions_set; }

    void ws_protocol (const string& v)    { _ws_protocol = v; }
    void error       (const ErrorCode& e) { _error = e; }

    void ws_extensions (const HeaderValues& new_extensions) {
        _ws_extensions = new_extensions;
        _ws_extensions_set = true;
    }

    string to_string();

private:
    friend struct ServerParser; friend struct ClientParser;

    string       _ws_key;
    HeaderValues _ws_extensions;
    bool         _ws_extensions_set;
    string       _ws_accept_key;
    string       _ws_version;
    string       _ws_protocol;
    ErrorCode    _error;

    string _calc_accept_key (string ws_key);
};

using ConnectResponseSP = panda::iptr<ConnectResponse>;

}}}
