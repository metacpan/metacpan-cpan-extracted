#pragma once
#include "Message.h"
#include <panda/date.h>
#include <panda/memory.h>
#include <panda/optional.h>

namespace panda { namespace protocol { namespace http {

struct Request;

extern const panda::time::Timezone* gmtz;

struct Response : Message, AllocatedObject<Response> {
    using Date = panda::date::Date;
    struct Builder; template <class, class> struct BuilderImpl;

    struct Cookie {
        enum class SameSite { disabled = 0, Strict, Lax, None };

        Cookie (const string& value = "", const string& domain = "", const string& path = "", uint64_t max_age = 0, bool secure = false,
                bool http_only = false, SameSite same_site = SameSite::disabled) :
            _value(value), _domain(domain), _path(path), _max_age(max_age), _secure(secure), _http_only(http_only), _same_site(same_site)
        {}

        const string&  value       () const { return _value; }
        const string&  domain      () const { return _domain; }
        const string&  path        () const { return _path; }
        uint64_t       max_age     () const { return _max_age; }
        optional<Date> expires     () const { if (!_expires) return {}; return Date(_expires); }
        bool           secure      () const { return _secure; }
        bool           http_only   () const { return _http_only; }
        SameSite       same_site   () const { return _same_site; }
        int64_t        max_age_any () const;
        optional<Date> expires_any () const;

        Cookie& value     (const string& v) { _value     = v; return *this; }
        Cookie& domain    (const string& v) { _domain    = v; return *this; }
        Cookie& path      (const string& v) { _path      = v; return *this; }
        Cookie& max_age   (uint64_t v)      { _max_age   = v; _expires.clear(); return *this; }
        Cookie& secure    (bool v)          { _secure    = v; return *this; }
        Cookie& http_only (bool v)          { _http_only = v; return *this; }
        Cookie& same_site (SameSite v)      { _same_site = v; return *this; }

        Cookie& expires (const Date& _d) {
            auto d = _d;
            d.to_timezone(gmtz);
            _expires = d.to_string(Date::Format::rfc1123);
            _max_age = 0;
            return *this;
        }

        string to_string (const string& cookie_name, const Request* context = nullptr) const;
        void serialize_to (string& acc, const string& name, const Request* req = nullptr) const;

    private:
        friend struct ResponseParser; friend struct RequestParser;

        string   _value;
        string   _domain;
        string   _path;
        uint64_t _max_age   = 0;
        string   _expires;
        bool     _secure    = false;
        bool     _http_only = false;
        SameSite _same_site = SameSite::disabled;
    };

    struct Cookies : Fields<Cookie, true, 2> {
        optional<Cookie> get (const string& key) {
            auto it = find(key);
            if (it == fields.cend()) return {};
            return it->value;
        }
    };

    int     code = 0;
    string  message;
    Cookies cookies;

    Response () : code() {}

    Response (int code, Headers&& header = Headers(), Body&& body = Body(), bool chunked = false, int http_version = 0, const string& message = {}) :
        Message(std::move(header), std::move(body), chunked, http_version), code(code), message(message)
    {}

    string full_message () const { return panda::to_string(code) + " " + (message ? message : message_for_code(code)); }

    std::vector<string> to_vector (const Request* req = nullptr);
    string              to_string (const Request* req = nullptr) { return Message::to_string(to_vector(req)); }

    static string message_for_code (int code);

    void parse_set_cookie (const string& buffer);

protected:
    ~Response () {}

private:
    friend struct ResponseParser;

    string _http_header (const Request*, Compression::Type) const;
};
using ResponseSP = iptr<Response>;

template <class T, class R>
struct Response::BuilderImpl : Message::Builder<T, R> {
    using Message::Builder<T, R>::Builder;

    T& code (int code) {
        this->_message->code = code;
        return this->self();
    }

    T& message (const string& message) {
        this->_message->message = message;
        return this->self();
    }

    T& cookie (const string& name, const Response::Cookie& coo) {
        this->_message->cookies.add(name, coo);
        return this->self();
    }
};

struct Response::Builder : Response::BuilderImpl<Builder, ResponseSP> {
    Builder () : BuilderImpl(new Response()) {}
};

}}}
