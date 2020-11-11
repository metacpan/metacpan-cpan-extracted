#include "Response.h"
#include "Request.h"
#include <ctime>

namespace panda { namespace protocol { namespace http {

const panda::time::Timezone* gmtz = panda::time::tzget("GMT");

int64_t Response::Cookie::max_age_any () const {
    if (_max_age || !_expires) return _max_age;
    return Date(_expires).epoch() - std::time(nullptr);
}

optional<date::Date> Response::Cookie::expires_any () const {
    if (!_max_age) return expires();
    auto ret = Date::now();
    ret.epoch(ret.epoch() + _max_age);
    return ret;
}

string Response::Cookie::to_string (const string& name, const Request* req) const {
    string str(200); // should be enough for average set-cookie header
    serialize_to(str, name, req);
    return str;
}

void Response::Cookie::serialize_to (string& acc, const string& name, const Request* req) const {
    acc += name;
    acc += '=';
    acc += _value;

    const string& domain = !_domain && req ? req->headers.get("Host") : _domain;
    if (domain) {
        acc += "; Domain=";
        acc += domain;
    }

    if (_path) {
        acc += "; Path=";
        acc += _path;
    }

    if (_max_age) {
        acc += "; Max-Age=";
        acc += panda::to_string(_max_age);
    }
    else if (_expires) {
        acc += "; Expires=";
        acc += _expires;
    }

    if (_secure)    acc += "; Secure";
    if (_http_only) acc += "; HttpOnly";

    switch (_same_site) {
        case SameSite::None   : acc += "; SameSite=None"; break;
        case SameSite::Lax    : acc += "; SameSite=Lax";  break;
        case SameSite::Strict : acc += "; SameSite";      break;
        default               : {}
    }
}

string Response::_http_header (SerializationContext &ctx) const {
    //part 1: precalc pieces
    auto req = ctx.request;
    auto tmp_http_ver = ctx.http_version;
    auto tmp_code = code ? code : 200;

    auto out_connection = headers.get("Connection");
    if (req) {
        if (!tmp_http_ver) tmp_http_ver = req->http_version;

        if (req->keep_alive()) { // user can change connection to 'close'
            if (tmp_http_ver == 10 && !out_connection) out_connection = "keep-alive";
        }
        else { // user can not change connection to 'keep-alive'
            if (tmp_http_ver == 10) out_connection = "";
            else                    out_connection = "close";
        }
    }

    auto out_mesasge = message ? message : message_for_code(tmp_code);

    string out_content_length;
    if (!chunked && !headers.has("Content-Length")) {
        out_content_length = panda::to_string(ctx.body->length());
    }

    auto out_content_encoding = _content_encoding(ctx);

    // part 2: summarize pieces size
    size_t reserved = 5 + 4 + 4 + out_mesasge.length() + 2 + headers.length() + 2;
    if (out_connection)       reserved += 10 + 2 + out_connection.length()   + 2;
    if (out_content_length)   reserved += 14 + 2 + out_content_length.length()   + 2;
    if (out_content_encoding) reserved += 16 + 2 + out_content_encoding.length() + 2;

    for (auto& h: ctx.handled_headers) reserved += h.name.length() + 2 + h.value.length() + 2;
    for (auto& h: headers) {
        if (ctx.handled_headers.has(h.name)) continue;  // let's speedup a little bit
        if (h.name == "Connection") continue;  // already handled
        reserved += h.name.length() + 2 + h.value.length() + 2;
    };
    reserved += (200 + 14) * cookies.fields.size(); // should be enough for average set-cookie header
    reserved += 2;

    // part 3: write out pieces
    string s(reserved);
    s += "HTTP/";
    switch (tmp_http_ver) {
        case 0:
        case 11: s += "1.1 "; break;
        case 10: s += "1.0 "; break;
        default: assert(false && "invalid http version");
    }
    s += panda::to_string(tmp_code);
    s += ' ';
    s += out_mesasge;
    s += "\r\n";

    if (out_connection)       { s += "Connection: "      ; s += out_connection      ; s += "\r\n" ;};
    if (out_content_length)   { s += "Content-Length: "  ; s += out_content_length  ; s += "\r\n" ;};
    if (out_content_encoding) { s += "Content-Encoding: "; s += out_content_encoding; s += "\r\n" ;};

    for (auto& h: ctx.handled_headers) { s += h.name; s += ": "; s += h.value; s+= "\r\n"; }
    for (auto& h: headers)  {
        if (ctx.handled_headers.has(h.name)) continue;
        if (h.name == "Connection") continue;  // already handled
        s += h.name; s += ": "; s += h.value; s+= "\r\n";
    };
    for (auto& c: cookies.fields) {
        s += "Set-Cookie: ";
        c.value.serialize_to(s, c.name, req);
        s += "\r\n";
    }

    s += "\r\n";

    //assert(reserved >= s.length());
    return s;
}

std::vector<string> Response::to_vector (const Request* req) const {
    /* if client didn't announce Accept-Encoding or we do not support it, just pass data as it is */
    auto applied_compression
            = req && (compression.type != Compression::IDENTITY) && (req->allowed_compression() & (uint8_t)compression.type)
            ? compression.type
            : Compression::IDENTITY;

    SerializationContext ctx;
    ctx.compression = applied_compression;
    ctx.request = req;
    ctx.body    = &body;
    ctx.chunked = this->chunked;

    return _to_vector(ctx, [&]() { return _compile_prepare(ctx); }, [&]() { return _http_header(ctx); });
}

string Response::message_for_code (int code) {
    switch (code) {
        case 100: return "Continue";
        case 101: return "Switching Protocol";
        case 102: return "Processing";
        case 103: return "Early Hints";
        case 200: return "OK";
        case 201: return "Created";
        case 202: return "Accepted";
        case 203: return "Non-Authoritative Information";
        case 204: return "No Content";
        case 205: return "Reset Content";
        case 206: return "Partial Content";
        case 300: return "Multiple Choice";
        case 301: return "Moved Permanently";
        case 302: return "Found";
        case 303: return "See Other";
        case 304: return "Not Modified";
        case 305: return "Use Proxy";
        case 306: return "Switch Proxy";
        case 307: return "Temporary Redirect";
        case 308: return "Permanent Redirect";
        case 400: return "Bad Request";
        case 401: return "Unauthorized";
        case 402: return "Payment Required";
        case 403: return "Forbidden";
        case 404: return "Not Found";
        case 405: return "Method Not Allowed";
        case 406: return "Not Acceptable";
        case 407: return "Proxy Authentication Required";
        case 408: return "Request Timeout";
        case 409: return "Conflict";
        case 410: return "Gone";
        case 411: return "Length Required";
        case 412: return "Precondition Failed";
        case 413: return "Request Entity Too Large";
        case 414: return "Request-URI Too Long";
        case 415: return "Unsupported Media Type";
        case 416: return "Requested Range Not Satisfiable";
        case 417: return "Expectation Failed";
        case 500: return "Internal Server Error";
        case 501: return "Not Implemented";
        case 502: return "Bad Gateway";
        case 503: return "Service Unavailable";
        case 504: return "Gateway Timeout";
        case 505: return "HTTP Version Not Supported";
        default : return {};
    }
}

}}}
