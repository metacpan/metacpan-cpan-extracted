#include "ServerParser.h"
#include <sstream>
#include <exception>

namespace panda { namespace protocol { namespace websocket {

struct RequestFactory : http::RequestParser::IFactory {
    http::RequestSP new_request () override {
        return make_iptr<ConnectRequest>();
    }
};

ServerParser::ServerParser (const Parser::Config& cfg) : Parser(true, cfg), _connect_parser(new RequestFactory) {
    _connect_parser.max_body_size = 0;
}

ConnectRequestSP ServerParser::accept (string& buf) {
    if (_flags[ACCEPT_PARSED]) throw Error("already parsed accept");
    _connect_parser.max_headers_size = _max_handshake_size;

    http::RequestParser::Result res = _connect_parser.parse(buf);
    _connect_request = dynamic_pointer_cast<ConnectRequest>(res.request);

    if (res.error) {
        _flags.set(ACCEPT_PARSED);
        _connect_request->error = res.error;
        return _connect_request;
    } else if (res.state != http::State::done) {
        return nullptr;
    }

    _connect_request->process_headers();
    _flags.set(ACCEPT_PARSED);

    if (!_connect_request->error) {
        if (res.position != buf.size()) {
            _connect_request->error = errc::garbage_after_connect;
        } else {
            _flags.set(ACCEPTED);
        }
    }

    return _connect_request;
}

string ServerParser::accept_error () {
    if (!_flags[ACCEPT_PARSED]) throw Error("accept not parsed yet");
    if (established()) throw Error("already established");
    if (!_connect_request->error) throw Error("no errors found");

    http::ResponseSP res = new http::Response();
    res->headers.add("Content-Type", "text/plain");

    if (!_connect_request->ws_version_supported()) {
        res->code    = 426;
        res->message = "Upgrade Required";
        res->body.parts.push_back("426 Upgrade Required");

        string svers(50);
        for (int v : supported_ws_versions) {
            svers += string::from_number(v);
            svers += ", ";
        }
        if (svers) svers.length(svers.length()-2);
        res->headers.add("Sec-WebSocket-Version", svers);
    }
    else {
        res->code    = 400;
        res->message = "Bad Request";
        res->body.parts.push_back("400 Bad Request\n");
        res->body.parts.push_back(_connect_request->error.what());
    }
    res->headers.set("Content-Length", panda::to_string(res->body.length()));

    return res->to_string(_connect_request);
}

string ServerParser::accept_error (http::Response* res) {
    if (!_flags[ACCEPT_PARSED]) throw Error("accept not parsed yet");
    if (established()) throw Error("already established");
    if (_connect_request->error) return accept_error();

    if (!res->code) {
        res->code = 400;
        res->message = "Bad Request";
    }
    else if (!res->message) res->message = "Unknown";

    if (res->body.empty()) {
        res->body.parts.push_back(string::from_number(res->code) + ' ' + res->message);
    }

    if (!res->headers.has("Content-Type")) res->headers.add("Content-Type", "text/plain");
    if (!res->headers.has("Content-Length")) res->headers.add("Content-Length", panda::to_string(res->body.length()));

    return res->to_string(_connect_request);
}

string ServerParser::accept_response (ConnectResponse* res) {
    if (!accepted()) throw Error("client has not been accepted");
    if (established()) throw Error("already established");

    res->_ws_key = _connect_request->ws_key;
    if (!res->ws_protocol) res->ws_protocol = _connect_request->ws_protocol;
    if (!res->ws_extensions_set()) res->ws_extensions(_connect_request->ws_extensions());

    const auto& exts = res->ws_extensions();
    HeaderValues used_extensions;
    if (_deflate_cfg && exts.size()) {
        // filter extensions
        auto role = DeflateExt::Role::SERVER;
        auto deflate_matches = DeflateExt::select(exts, *_deflate_cfg, role);
        if (deflate_matches) {
            _deflate_ext.reset(DeflateExt::uplift(deflate_matches, used_extensions, role));
        }
    }
    res->ws_extensions(std::move(used_extensions));

    _flags.set(ESTABLISHED);
    _connect_request = NULL;
    return res->to_string();
}

void ServerParser::reset () {
    _connect_request = NULL;
    _connect_parser.reset();
    Parser::reset();
}

ServerParser::~ServerParser() {}

}}}
