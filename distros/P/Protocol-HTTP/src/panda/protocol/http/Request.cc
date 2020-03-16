#include "Request.h"

namespace panda { namespace protocol { namespace http {

static inline string _method_str (Request::Method rm) {
    using Method = Request::Method;
    switch (rm) {
        case Method::OPTIONS : return "OPTIONS";
        case Method::GET     : return "GET";
        case Method::HEAD    : return "HEAD";
        case Method::POST    : return "POST";
        case Method::PUT     : return "PUT";
        case Method::DELETE  : return "DELETE";
        case Method::TRACE   : return "TRACE";
        case Method::CONNECT : return "CONNECT";
        default: return "[UNKNOWN]";
    }
}

string Request::http_header (Compression::Type applied_compression) const {
    //part 1: precalc pieces
    auto out_meth = _method_str(method);

    auto out_reluri  = uri ? uri->relative() : string("/");

    auto tmp_http_ver = !http_version ? 11 : http_version;
    string out_content_length;
    if (!chunked && body.parts.size() && !headers.has("Content-Length")) {
        out_content_length = panda::to_string(body.length());
    }

    size_t sz_host = 0;
    size_t sz_host_port = 0;
    if (!headers.has("Host") && uri && uri->host()) {
        // Host field builder
        // See https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Host
        sz_host = uri->host().length();
        auto& scheme = uri->scheme();
        auto port = uri->port();
        if ((!scheme) || (scheme == "http" && port != 80) || (scheme == "https" && port != 443)) {
            sz_host_port = 6;
        }
    }

    string out_accept_encoding;
    if (compression_prefs && compression_prefs != static_cast<compression::storage_t>(Compression::IDENTITY) && !headers.has("Accept-Encoding")) {
        string comp_pos, comp_neg;
        int index_pos = 0, index_neg = 0;
        compression::for_each(compression_prefs, [&](auto value, bool negation){
            const char* val = nullptr;
            switch (value) {
                case Compression::GZIP   : val = "gzip"; break;
                case Compression::BROTLI : val = "br";   break;
                default: return;
            }
            if (negation) {
                if (index_neg) { comp_neg += ", "; }
                comp_neg += val;
                comp_neg += ";q=0";
                ++index_neg;
            }  else {
                if (index_pos) { comp_pos += ", "; }
                comp_pos += val;
                ++index_pos;
            }
        });
        if (index_neg) {
            if (index_pos) { comp_pos += ", "; }
             comp_pos += comp_neg;
        }
        if (comp_pos) { out_accept_encoding = comp_pos; }
    }

    auto out_content_encoding = _content_encoding(applied_compression);
    size_t sz_cookies = 0;
    if (cookies.size()) {
        for (auto& f : cookies.fields) sz_cookies += f.name.length() + f.value.length() + 3; // 3 for ' ', '=' and ';' for each pair
    }

    // part 2: summarize pieces size
    size_t reserved = out_meth.length();
    reserved += out_reluri.length();
    reserved += 5 + 6 + 2 + 1;   /* http-version  + trailer */

    if (out_content_length)   reserved += 14 + 2 + out_content_length.length()   + 2;
    if (sz_host)              reserved += 4  + 2 + sz_host + sz_host_port        + 2;
    if (out_accept_encoding)  reserved += 15 + 2 + out_accept_encoding.length()  + 2;
    if (out_content_encoding) reserved += 16 + 2 + out_content_encoding.length() + 2;
    if (sz_cookies)           reserved += 6  + 2 + sz_cookies                    + 2;

    for (auto& h: headers) { reserved += h.name.length() + 2 + h.value.length() + 2; };

    // part 3: write out pieces
    string s(reserved);
    s += out_meth;
    s += ' ';
    s += out_reluri;
    s += " HTTP/";
    if (tmp_http_ver == 11) s += "1.1\r\n";
    else                    s += "1.0\r\n";

    if (sz_host) {
        s += "Host: " ;
        s += uri->host();
        if (sz_host_port) { s+= ":";  s += panda::to_string(uri->port()); }
        s += "\r\n";
    };

    if (out_content_length)   { s += "Content-Length: "  ; s += out_content_length  ; s += "\r\n" ;};
    if (out_accept_encoding)  { s += "Accept-Encoding: " ; s += out_accept_encoding ; s += "\r\n" ;};
    if (out_content_encoding) { s += "Content-Encoding: "; s += out_content_encoding; s += "\r\n" ;};

    if (sz_cookies) {
        s += "Cookie: ";
        auto sz = cookies.size();
        for (size_t i = 0; i < sz; ++i) {
            if (i) { s += "; "; }
            const auto& f = cookies.fields[i];
            s += f.name;
            s += '=';
            s += f.value;
        }
        s += "\r\n";
    }

    if (headers.size()) {
        for (auto& h: headers) {  s += h.name; s += ": "; s += h.value; s+= "\r\n"; };
    }
    s += "\r\n";

    //assert((sz_cookies + headers.size()) ==  0);
    //assert(reserved >= s.length());

    return s;
}

std::vector<string> Request::to_vector () {
    return _to_vector(compression.type, [this]{ return http_header(compression.type); });
}

bool Request::expects_continue () const {
    for (auto& val : headers.get_multi("Expect")) if (val == "100-continue") return true;
    return false;
}

std::uint8_t Request::allowed_compression (bool inverse) const noexcept {
    std::uint8_t result = 0;
    compression::for_each(compression_prefs, [&](auto value, bool negation){
        if (inverse == negation) {
            result |= value;
        }
    });
    return result;
}

}}}
