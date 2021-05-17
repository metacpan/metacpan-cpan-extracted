#include "http.h"
#include <cstring>
#include <xs/date.h>

namespace xs { namespace protocol { namespace http {

using panda::string;

static inline void msgfill (Message* m, const Hash& h) {
    for (auto& row : h) {
        auto key = row.key();
        if (!key.length()) continue;
        auto v = row.value();
        switch (key[0]) {
            case 'h':
                if      (key == "headers")      set_headers(m, v);
                else if (key == "http_version") m->http_version = Simple(v);
                break;
            case 'b':
                if (key == "body") m->body = xs::in<string>(v);
                break;
            case 'c':
                if      (key == "chunked") m->chunked = v.is_true();
                else if (key == "compress") {
                    if (v.is_array_ref()) {
                        Array a(v);
                        switch (a.size()) {
                            case 2: m->compression.level = (Compression::Level)SvIV(a[1]);
                                    // fall through
                            case 1: m->compression.type  = (Compression::Type)SvIV(a[0]);
                        }
                    }
                    else m->compression.type = (Compression::Type)SvIV(v);
                }
                break;
        }
    }
}

static Request::EncType get_encoding(const Sv& sv) {
    using Type = Request::EncType;
    int val = SvIV(sv);
    if (val < (int)Type::Multipart || val > (int)Type::UrlEncoded) throw "invalid form encoding";
    return (Type)val;
}

static void fill(Request::Form& form, Array& arr, Request::EncType enc_type)  {
    if (arr.size()) {
        form.enc_type(enc_type);
        bool even = arr.size() % 2 == 0;
        size_t last = even ? arr.size() - 1 : arr.size() - 2;
        for(size_t i = 0; i < last; i += 2) {
            string key = arr.at(i).as_string();
            auto value = arr.at(i +1);
            if (value.is_simple()) {
                form.add(key, value.as_string());
            }
            else if(value.is_array_ref()) {
                auto values = Array(value);
                if (values.size() != 3) {
                    string err = "invalid file fieild '";
                    err += key;
                    err += ": it should be array [$filename => $filecontent, $filetype]";
                    throw err;
                }
                form.add(key, values[1].as_string(), values[0].as_string(), values[2].as_string());
            }
        }
        if (!even) {
            string key = arr.back().as_string();
            form.add(key, "");
        }
    }
}

void fill_form(Request* req, const Sv& sv) {
    if (!sv || !sv.defined()) return;
    auto& form = req->form;
    if (sv.is_hash_ref()) {
        Hash h(sv);
        Request::EncType type = h.exists("enc_type") ? get_encoding(h.fetch("enc_type")) : Request::EncType::Multipart;
        Sv fields;
        if ((fields = h.fetch("fields"))) {
            Array arr(fields);
            fill(form, arr, type);
        }
        else form.enc_type(type);
    }
    else if (sv.is_array_ref()) {
        Array arr(sv);
        fill(form, arr, Request::EncType::Multipart);
    }
    else form.enc_type(get_encoding(sv));
}


void fill (Request* req, const Hash& h) {
    msgfill(req, h);
    for (auto& row : h) {
        auto key = row.key();
        if (!key.length()) continue;
        auto v = row.value();
        switch (key[0]) {
            case 'm':
                if (key == "method") { if (v.defined()) set_method(req, v); }
                break;
            case 'u':
                if (key == "uri") req->uri = xs::in<URISP>(v);
                break;
            case 'c':
                if (key == "cookies") set_request_cookies(req, v);
                break;
            case 'a':
                if (key == "allow_compression") {
                    if (v.is_array_ref()) {
                        Array av(v);
                        for (auto value : av) {
                            auto val = value.as_number<uint8_t>();
                            if (is_valid_compression(val)) req->allow_compression((Compression::Type)val);
                        }
                    }
                    else {
                        uint8_t val = SvIV(v);
                        if (is_valid_compression(val)) req->allow_compression((Compression::Type)val);
                    }
                }
                break;
        }
    }
}

void fill (Response* res, const Hash& h) {
    msgfill(res, h);
    for (auto& row : h) {
        auto key = row.key();
        if (!key.length()) continue;
        auto v = row.value();
        switch (key[0]) {
            case 'c':
                if      (key == "code")    res->code = Simple(v);
                else if (key == "cookies") set_response_cookies(res, v);
                break;
            case 'm':
                if (key == "message") res->message = Simple(v).as_string();
                break;
        }
    }
}

void set_headers (Message* p, const Hash& hv) {
    p->headers.clear();
    for (const auto& row : hv) p->headers.add(string(row.key()), xs::in<string>(row.value()));
}

void set_method (Request* req, const Sv& method) {
    using Method = Request::Method;
    int num = SvIV_nomg(method);
    if (num < (int)Method::Options || num > (int)Method::Connect) throw panda::exception("invalid http method");
    req->method_raw((Method)num);
}

void set_request_cookies (Request* p, const Hash& hv) {
    p->cookies.clear();
    for (const auto& row : hv) p->cookies.add(string(row.key()), xs::in<string>(row.value()));
}

void set_response_cookies (Response* p, const Hash& hv) {
    p->cookies.clear();
    for (const auto& row : hv) p->cookies.add(string(row.key()), xs::in<Response::Cookie>(row.value()));
}

}}}

namespace xs {

using Response = panda::protocol::http::Response;
using CookieJar = panda::protocol::http::CookieJar;

Response::Cookie Typemap<Response::Cookie>::in (const Hash& h) {
    Response::Cookie c;
    Sv sv; Simple v;
    if ((v  = h.fetch("value")))     c.value(v.as_string());
    if ((v  = h.fetch("domain")))    c.domain(v.as_string());
    if ((v  = h.fetch("path")))      c.path(v.as_string());
    if ((sv = h.fetch("expires")))   c.expires(xs::in<panda::date::Date>(sv));
    if ((v  = h.fetch("max_age")))   c.max_age(v);
    if ((sv = h.fetch("secure")))    c.secure(sv.is_true());
    if ((sv = h.fetch("http_only"))) c.http_only(sv.is_true());
    if ((v  = h.fetch("same_site"))) c.same_site((Cookie::SameSite)(int)v);
    return c;
}

Sv Typemap<Response::Cookie>::out (const Response::Cookie& c, const Sv& ) {
    Hash h = Hash::create();
    h["value"]     = xs::out(c.value());
    h["secure"]    = xs::out(c.secure());
    h["http_only"] = xs::out(c.http_only());
    h["same_site"] = xs::out((int)c.same_site());

    if (c.domain())  { h["domain"]  = xs::out(c.domain());  }
    if (c.path())    { h["path"]    = xs::out(c.path());    }
    if (c.expires()) { h["expires"] = xs::out(c.expires()); }
    if (c.max_age()) { h["max_age"] = xs::out(c.max_age()); }
    return Ref::create(h);
}

Sv Typemap<CookieJar::Cookie>::out (const CookieJar::Cookie& c, const Sv&) {
    Ref r = xs::out<Response::Cookie>(c);
    Hash h(r);
    h["name"]      = xs::out(c.name());
    h["host_only"] = c.host_only() ? Simple::yes : Simple::no;
    if (c.origin()) h["origin"] = xs::out(c.origin());
    return std::move(r);
}

Sv Typemap<CookieJar::Cookies>::out(const CookieJar::Cookies& cookies, const Sv&) {
    auto r = Array::create(cookies.size());
    for (auto& coo: cookies) r.push(xs::out(coo));
    return Ref::create(r);
}

Sv Typemap<CookieJar::DomainCookies>::out(const DomainCookies& domain_cookies, const Sv&) {
    Hash h = Hash::create();
    for(auto& pair : domain_cookies) {
        auto domain = pair.first.substr(1); // cut "." part
        h[domain] = xs::out(pair.second);
    }
    return Ref::create(h);
}

}
