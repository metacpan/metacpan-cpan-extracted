#include "Request.h"
#include <ctime>
#include <cstdlib>
#include <type_traits>

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

string Request::_generate_boundary() noexcept {
    const constexpr size_t SZ = (string::MAX_SSO_CHARS / sizeof (int)) + (string::MAX_SSO_CHARS % sizeof (int) == 0 ? 0 : 1);
    const constexpr char alphabet[] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
    const constexpr size_t alphabet_sz = sizeof (alphabet) - 1;
    int dices[SZ];
    string r(40, '-');
    for(size_t i = 0; i <SZ; ++i) { dices[i] = std::rand(); }

    const char* random_bytes = (const char*)dices;
    for(size_t i = r.size() - 17; i < r.size(); ++i) {
        r[i] = alphabet[*random_bytes++ % alphabet_sz];
    }

    return r;
}

Request::Method Request::method() const noexcept {
    if (_method == Method::unspecified) {
        bool use_post = (form && form.enc_type() == EncType::MULTIPART && (!form.empty() || (uri && !uri->query().empty()))) // complete form
                     || _form_streaming != FormStreaming::none;
        return use_post ? Method::POST : Method::GET;
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
              = !ctx.chunked
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
    if (_form_streaming != FormStreaming::none && _form_streaming != FormStreaming::started)
        throw "form streaming wasn't finished";

    bool form_streaming =  _form_streaming == FormStreaming::started;
    /* it seems nobody supports muliptart + gzip + chunk */
    ctx.compression = !form_streaming ? compression.type : Compression::Type::IDENTITY;
    ctx.body        = &body;
    ctx.uri         = uri.get();
    ctx.chunked     = this->chunked || form_streaming;

    auto add_form_header = [&](auto& boundary) {
        string ct = "multipart/form-data; boundary=";
        ct += boundary;
        ctx.handled_headers.add("Content-Type", ct);
    };

    Body form_body;
    URI form_uri;
    if (form) {
        if (form.enc_type() == EncType::MULTIPART) {
            if (!form.empty() || (uri && !uri->query().empty())) {
                auto boundary = form_streaming ? _form_boundary : _generate_boundary();
                ctx.uri  = form.to_body(form_body, form_uri, uri, boundary);
                ctx.body = &form_body;
                add_form_header(boundary);
            } else if (form_streaming) {
                add_form_header(_form_boundary);
            }
        }
        else if((form.enc_type() == EncType::URLENCODED) && !form.empty()) {
            form.to_uri(form_uri, uri);
            ctx.uri = &form_uri;
        }
    }
    else if (form_streaming) {
        add_form_header(_form_boundary);
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

static string form_trailer(const string& boundary) noexcept {
    auto sz = boundary.size() + 6;
    string r(sz);
    r += "--";
    r += boundary;
    r += "--\r\n";
    return r;
}

namespace tag {
    using uri = std::integral_constant<int, 0>;
    using form = std::integral_constant<int, 1>;
}

template<typename Tag> struct Helper;

template<> struct Helper<tag::form> {
    using Field =  Request::Form::value_type;

    struct PatrialField {
        string name;
        string mime_type;
        string filename;
        bool complete = false;
    };

    struct FullField: PatrialField {
        FullField(const string& name_, const string& filename_, const string& mime_type_, const string& value_):
            PatrialField{name_, mime_type_, filename_, true}, value{value_}{}
        string value;
    };

    static size_t buffer_size(const string &boundary, const Request::Form& container) noexcept {
        auto fields_count = container.size();
        size_t size = (
                boundary.length() + 4   /* "--" prefix and "\r\n" */
                + 37 + 2                /* Content-Disposition: form-data; name="" + \r\n */
            ) * fields_count  + 2;      /* -- */
        for(auto it : container) {
            size += it.second.value.length();
            auto& name = it.second.name;
            if (name) {
                size += name.length() + 14;   //; filename=""
            }
            auto& ct = it.second.content_type;
            if (ct) {
                size += ct.size() + 18; //Content-Type: xxx\r\n
            }
        }
        return size;
    }

    static void append_header(string& r, const string& header, const string& value) noexcept {
        r += header;
        r += ": ";
        r += value;
        r += "\r\n";
    }

    static void append(string& r, const PatrialField& field, const string& boundary) noexcept {
        r += "--";
        r += boundary;
        r += "\r\n";
        r += "Content-Disposition: form-data; name=\"";
        r += field.name;
        r += "\"";
        if (field.filename) {
            r+= "; filename=\"";
            r += field.filename;
            r += "\"";
        }
        r += "\r\n";

        if (field.mime_type) {
            r += "Content-Type: ";
            r += field.mime_type;
            r += "\r\n";
        }

        if (field.complete) r += "\r\n";
    }

    static void append(string& r, const FullField& field, const string& boundary) noexcept {
        append(r, (const PatrialField&)field, boundary);
        r += field.value;
        r += "\r\n";
    }

    static void append(string& r, const Field& it, const string& boundary) noexcept {
        append(r, FullField{it.first, it.second.name, it.second.content_type, it.second.value}, boundary);
    }

};

template<> struct Helper<tag::uri> {
    using Field =  string_multimap<string, string>::value_type;

    static size_t buffer_size(const string &boundary, const string_multimap<string, string>& container) noexcept {
        auto fields_count= container.size();
        size_t size = (
                boundary.length() + 4   /* "--" prefix and "\r\n" */
                + 37 + 2                /* Content-Disposition: form-data; name="" + \r\n */
            ) * fields_count  + 2;      /* -- */
        for(auto it : container) {
            size += it.second.length();
        }
        return size;
    }

    static void append(string& r, const Field& it, const string& boundary) noexcept {
        r += "--";
        r += boundary;
        r += "\r\n";
        r += "Content-Disposition: form-data; name=\"";
        r += it.first;
        r += "\"";
        r += "\r\n";
        r += "\r\n";
        r += it.second;
        r += "\r\n";
    }
};

void Request::form_file_finalize(string& out) noexcept {
    if (_form_streaming == FormStreaming::file) {
        if (compressor) {
            out += compressor->flush();
            compressor.reset();
        }
        out += "\r\n"; /* finalize file */
    }
}


Request::wrapped_chunk Request::form_finish() {
    if (_form_streaming == FormStreaming::none) throw "form streaming was not started";
    if (_form_streaming == FormStreaming::done) throw "form streaming already complete";

    string data;
    form_file_finalize(data);
    data += form_trailer(_form_boundary);
    _form_streaming = FormStreaming::done;
    return final_chunk(data);
}

Request::wrapped_chunk Request::form_field(const string& name, const string& content, const string& filename, const string& mime_type) {
    using H = Helper<tag::form>;
    if (_form_streaming == FormStreaming::none) throw "form streaming was not started";
    if (_form_streaming == FormStreaming::done) throw "form streaming already complete";

    string data;
    form_file_finalize(data);
    H::append(data, H::FullField{name, filename, mime_type, content}, _form_boundary);
    return make_chunk(data, compression::CompressorPtr{});  // we don't compress
}

Request::wrapped_chunk Request::form_file(const string& name, const string filename, const string& mime_type) {
    using H = Helper<tag::form>;
    if (_form_streaming == FormStreaming::none) throw "form streaming was not started";
    if (_form_streaming == FormStreaming::done) throw "form streaming already complete";

    string data;
    form_file_finalize(data);
    _form_streaming = FormStreaming::file;

    H::append(data, H::PatrialField{name, mime_type, filename, false}, _form_boundary);
    data += "\r\n";

    return make_chunk(data, compression::CompressorPtr{});  // we don't compress
}

Request::wrapped_chunk Request::form_data(const string& content) {
    if (_form_streaming != FormStreaming::file) throw "form file streaming was not started";
    return make_chunk(content);
}

template<typename Tag, typename Container>
void _serialize(Body& body, const string &boundary, const Container& container) {
    using H = Helper<Tag>;
    string r(H::buffer_size(boundary, container));
    for(auto it : container) { H::append(r, it, boundary); }
    r += form_trailer(boundary);
    body.parts.emplace_back(r);
}

const uri::URI *Request::Form::to_body(Body& body, uri::URI &uri, const uri::URISP original_uri, const string &boundary) const noexcept {
    if (empty()) {
        if (!original_uri) return {};
        auto& q = original_uri->query();
        _serialize<tag::uri>(body, boundary, q);
        uri = URI(*original_uri);
        uri.query().clear();
        return &uri;
    } else {
        _serialize<tag::form>(body, boundary, *this);
        return original_uri.get();
    }
}

void Request::Form::to_uri  (uri::URI &uri, const URISP original_uri) const  {
    if (original_uri) uri = *original_uri;
    else              uri = "/";
    auto& q = uri.query();
    for(auto it : *this) {
        auto& named = it.second;
        if (named.name) throw string("form contains named field (filename) " + it.second.value + ", it cannot be converted to URI");
        q.insert({it.first, it.second.value});
    }
}


}}}
