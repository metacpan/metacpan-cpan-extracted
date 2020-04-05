#pragma once
#include "HeaderValueParamsParser.h"
#include <panda/refcnt.h>
#include <panda/error.h>
#include <panda/protocol/http/Response.h>

namespace panda { namespace protocol { namespace websocket {

struct ConnectResponse : http::Response {
    string ws_protocol;
    ErrorCode error;

    ConnectResponse () : _ws_extensions_set(false) {}

    virtual void process_headers ();

    const string& ws_accept_key () const { return _ws_accept_key; }
    const string& ws_version    () const { return _ws_version; }

    const HeaderValues& ws_extensions     () const { return _ws_extensions; }
    bool                ws_extensions_set () const { return _ws_extensions_set; }

    void ws_extensions (const HeaderValues& new_extensions) {
        _ws_extensions = new_extensions;
        _ws_extensions_set = true;
    }

    string to_string();

    friend struct ServerParser;
    friend struct ClientParser;

protected:
//    virtual void _to_string    (string& str);

private:
    string       _ws_key;
    HeaderValues _ws_extensions;
    bool         _ws_extensions_set;
    string       _ws_accept_key;
    string       _ws_version;

    string _calc_accept_key (string ws_key);
};

using ConnectResponseSP = panda::iptr<ConnectResponse>;

}}}
