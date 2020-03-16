#include "http.h"
#include <cstring>
#include <xs/date.h>

namespace xs { namespace protocol { namespace http {

using panda::string;

static inline void msgfill (Message* m, const Hash& h) {
    Sv sv;
    if ((sv = h.fetch("headers")))      set_headers(m, sv);
    if ((sv = h.fetch("body")))         m->body         = xs::in<string>(sv);
    if ((sv = h.fetch("http_version"))) m->http_version = Simple(sv);
    if ((sv = h.fetch("chunked")))      m->chunked      = sv.is_true();

    if ((sv = h.fetch("compress"))) {
        if (sv.is_array_ref()) {
            Array a(sv);
            switch (a.size()) {
                case 2: m->compression.level = (Compression::Level)SvIV(a[1]);
                case 1: m->compression.type  = (Compression::Type)SvIV(a[0]);
            }
        }
        else m->compression.type = (Compression::Type)SvIV(sv);
    }
}

void fill (Request* req, const Hash& h) {
    msgfill(req, h);
    Sv sv;
    if ((sv = h.fetch("method")) && sv.defined()) set_method(req, sv);
    if ((sv = h.fetch("uri")))                    req->uri = xs::in<URISP>(sv);
    if ((sv = h.fetch("cookies")))                set_request_cookies(req, sv);

    if ((sv = h.fetch("allow_compression"))) {
        if (sv.is_array_ref()) {
            Array av(sv);
            for (auto value : av) {
                auto val = value.as_number<uint8_t>();
                if (is_valid_compression(val)) req->allow_compression((Compression::Type)val);
            }
        }
        else {
            uint8_t val = SvIV(sv);
            if (is_valid_compression(val)) req->allow_compression((Compression::Type)val);
        }
    }
}

void fill (Response* res, const Hash& h) {
    msgfill(res, h);
    Sv sv; Simple v;
    if ((v  = h.fetch("code")))    res->code = v;
    if ((v  = h.fetch("message"))) res->message = v.as_string();
    if ((sv = h.fetch("cookies"))) set_response_cookies(res, sv);
}

void set_headers (Message* p, const Hash& hv) {
    p->headers.clear();
    for (const auto& row : hv) p->headers.add(string(row.key()), xs::in<string>(row.value()));
}

void set_method (Request* req, const Sv& method) {
    using Method = Request::Method;
    int num = SvIV_nomg(method);
    if (num < (int)Method::OPTIONS || num > (int)Method::CONNECT) throw panda::exception("invalid http method");
    req->method = (Method)num;
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

using Cookie = panda::protocol::http::Response::Cookie;

Cookie Typemap<Cookie>::in (const Hash& h) {
    Cookie c;
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

Sv Typemap<Cookie>::out (const Cookie& c, const Sv& ) {
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

}
