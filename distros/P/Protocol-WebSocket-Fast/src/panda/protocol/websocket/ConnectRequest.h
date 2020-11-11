#pragma once
#include "DeflateExt.h"
#include "HeaderValueParamsParser.h"
#include <panda/uri.h>
#include <panda/refcnt.h>
#include <panda/error.h>
#include <panda/protocol/http/Request.h>

namespace panda { namespace protocol { namespace websocket {

using panda::uri::URI;
using panda::uri::URISP;

static const int supported_ws_versions[] = {13};

struct ConnectRequest : http::Request {
    string       ws_key;
    int          ws_version;
    string       ws_protocol;

    ErrorCode error;

    ConnectRequest () : ws_version(0), _ws_version_supported(true) {
        _method = Request::Method::GET;
    }

    virtual void process_headers ();

    const HeaderValues& ws_extensions        () const { return _ws_extensions; }
    bool                ws_version_supported () const { return _ws_version_supported; }

    void ws_extensions (const HeaderValues& new_extensions) { _ws_extensions = new_extensions; }

    void add_deflate(const DeflateExt::Config& cfg);

    string to_string();

    http::ResponseSP new_response() const override;

protected:
//    virtual void _to_string    (string& str);

private:
    HeaderValues _ws_extensions;
    bool         _ws_version_supported;
};

using ConnectRequestSP = panda::iptr<ConnectRequest>;

}}}
