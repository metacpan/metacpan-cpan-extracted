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
    struct Builder; template <class, class> struct BuilderImpl;

    ConnectRequest () : _ws_version(0), _ws_version_supported(true) {
        _method = Request::Method::Get;
    }

    const string&       ws_key               () const { return _ws_key; }
    int                 ws_version           () const { return _ws_version; }
    const string&       ws_protocol          () const { return _ws_protocol; }
    const HeaderValues& ws_extensions        () const { return _ws_extensions; }
    bool                ws_version_supported () const { return _ws_version_supported; }
    const ErrorCode&    error                () const { return _error; }

    void ws_key        (const string& v)       { _ws_key = v; }
    void ws_version    (int v)                 { _ws_version = v; }
    void ws_protocol   (const string& v)       { _ws_protocol = v; }
    void ws_extensions (const HeaderValues& v) { _ws_extensions = v; }
    void error         (const ErrorCode& v)    { _error = v; }

    void add_deflate (const DeflateExt::Config& cfg);

    virtual void process_headers ();

    string to_string();

    http::ResponseSP new_response() const override;

private:
    string       _ws_key;
    int          _ws_version;
    string       _ws_protocol;
    HeaderValues _ws_extensions;
    bool         _ws_version_supported;
    ErrorCode    _error;
};

using ConnectRequestSP = panda::iptr<ConnectRequest>;

template <class T, class R>
struct ConnectRequest::BuilderImpl : http::Request::BuilderImpl<T, R> {
    using http::Request::BuilderImpl<T, R>::BuilderImpl;

    T& ws_key (const string& v) {
        this->_message->ws_key(v);
        return this->self();
    }

    T& ws_version (int v) {
        this->_message->ws_version(v);
        return this->self();
    }

    T& ws_protocol (const string& v) {
        this->_message->ws_protocol(v);
        return this->self();
    }

    T& ws_extensions (const HeaderValues& v) {
        this->_message->ws_extensions(v);
        return this->self();
    }

    T& add_deflate (const DeflateExt::Config& cfg) {
        this->_message->add_deflate(cfg);
        return this->self();
    }
};

struct ConnectRequest::Builder : ConnectRequest::BuilderImpl<Builder, ConnectRequestSP> {
    Builder () : BuilderImpl(new ConnectRequest()) {}
};

}}}
