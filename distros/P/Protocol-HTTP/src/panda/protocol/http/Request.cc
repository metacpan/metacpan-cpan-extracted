#include "Request.h"
#include <ctime>
#include <cstdlib>

namespace panda { namespace protocol { namespace http {

static bool _init () {
    std::srand(std::time(NULL));
    return true;
}

static const bool _inited = _init();

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

static inline string generate_boundary(const Request::Form& form) noexcept {
    const constexpr size_t SZ = (string::MAX_SSO_CHARS / sizeof (int)) + (string::MAX_SSO_CHARS % sizeof (int) == 0 ? 0 : 1);
    const constexpr char alphabet[] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
    const constexpr size_t alphabet_sz = sizeof (alphabet) - 1;
    int dices[SZ];
    bool matches_form;
    string r(40, '-');
    do {
        for(size_t i = 0; i <SZ; ++i) { dices[i] = std::rand(); }

        const char* random_bytes = (const char*)dices;
        for(size_t i = r.size() - 17; i < r.size(); ++i) {
            r[i] = alphabet[*random_bytes++ % alphabet_sz];
        }

        matches_form = false;
        for(auto it = form.begin(); (!matches_form) && (it != form.end()); ++it) {
            matches_form = (it->first.find(r) != string::npos) || (it->second.find(r) != string::npos);
        }
    } while(matches_form);
    return r;
}

Request::Method Request::method() const noexcept {
    if (_method == Method::unspecified) {
        if (form && form.enc_type() == EncType::MULTIPART && (!form.empty() || (uri && !uri->query().empty()))) {
            return Method::POST;
        }
        return Method::GET;
    }
    return _method;
}

static inline bool _method_has_meaning_for_body (Request::Method method) {
    return method == Request::Method::POST || method == Request::Method::PUT;
}

string Request::_http_header (SerializationContext& ctx) const {
    //part 1: precalc pieces
    auto eff_method  = method();
    bool body_method = _method_has_meaning_for_body(eff_method);
    auto out_meth    = _method_str(eff_method);
    auto eff_uri     = ctx.uri;

    auto out_reluri  = eff_uri ? eff_uri->relative() : string("/");

    auto tmp_http_ver = !ctx.http_version ? 11 : ctx.http_version;
    string out_content_length;
    bool calc_content_length
              = !chunked
            && (ctx.body->parts.size() || body_method)
            && !headers.has("Content-Length");
    if (calc_content_length) out_content_length = panda::to_string(ctx.body->length());

    size_t sz_host = 0;
    size_t sz_host_port = 0;
    if (!headers.has("Host") && eff_uri && eff_uri->host()) {
        // Host field builder
        // See https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Host
        sz_host = eff_uri->host().length();
        auto& scheme = eff_uri->scheme();
        auto port = eff_uri->port();
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

    auto out_content_encoding = _content_encoding(ctx);
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

    for (auto& h: ctx.handled_headers) { reserved += h.name.length() + 2 + h.value.length() + 2; }
    for (auto& h: headers)  {
        if (ctx.handled_headers.has(h.name)) continue;
        reserved += h.name.length() + 2 + h.value.length() + 2;
    }

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
        s += eff_uri->host();
        if (sz_host_port) { s+= ":";  s += panda::to_string(eff_uri->port()); }
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

    for (auto& h: ctx.handled_headers) { s += h.name; s += ": "; s += h.value; s+= "\r\n"; }
    for (auto& h: headers)  {
        if (ctx.handled_headers.has(h.name)) continue;
        s += h.name; s += ": "; s += h.value; s+= "\r\n";
    }
    s += "\r\n";

    //assert((sz_cookies + headers.size()) ==  0);
    //assert(reserved >= s.length());

    return s;
}

std::vector<string> Request::to_vector () const {
    SerializationContext ctx;
    ctx.compression = compression.type;
    ctx.body        = &body;
    ctx.uri         = uri.get();

    Body form_body;
    URI form_uri;
    if (form) {
        if (form.enc_type() == EncType::MULTIPART) {
            if (!form.empty() || (uri && !uri->query().empty())) {
                auto boundary = generate_boundary(form);
                form.to_body(form_body, form_uri, uri, boundary);
                string ct = "multipart/form-data; boundary=";
                ct += boundary;
                ctx.handled_headers.add("Content-Type", ct);
                ctx.body     = &form_body;
                ctx.uri      = &form_uri;
            }
        }
        else if((form.enc_type() == EncType::URLENCODED) && !form.empty()) {
            form.to_uri(form_uri, uri);
            ctx.uri = &form_uri;
        }
    }
    return _to_vector(ctx, [&]() { return _compile_prepare(ctx); }, [&]() { return _http_header(ctx); });
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

void Request::Form::to_body(Body& body, uri::URI &uri, const uri::URISP original_uri, const string &boundary) const noexcept {
    using Container = string_multimap<string, string>;

    auto serialize = [&body, &boundary](auto fields_count, const Container& container) {
        // pass 1: calc total
        size_t size = (
                boundary.length() + 2   /* \r\n */
                + 37 + 2                /* Content-Disposition: form-data; name="" + \r\n */
            ) * fields_count  + 2;      /* -- */
        for(auto it : container) size += it.second.length();

        // pass 2: merge strings
        string r(size);
        for(auto it : container) {
            r += boundary;
            r += "\r\n";
            r += "Content-Disposition: form-data; name=\"";
            r += it.first;
            r += "\"\r\n";
            r += "\r\n";
            r += it.second;
            r += "\r\n";
        }
        r += boundary;
        r += "--\r\n";

        body.parts.emplace_back(r);
    };

    if (empty()) {
        auto& q = original_uri->query();
        serialize(q.size(), q);
        uri = URI(*original_uri);
        uri.query().clear();
    } else {
        serialize(size(), *this);
    }
}

void Request::Form::to_uri  (uri::URI &uri, const URISP original_uri) const noexcept {
    if (original_uri) uri = *original_uri;
    else              uri = "/";
    auto& q = uri.query();
    for(auto it : *this) {
        q.insert({it.first, it.second});
    }
}


}}}
