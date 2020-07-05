#pragma once

#include <panda/string.h>
#include <panda/refcnt.h>
#include <panda/function.h>
#include <unordered_map>
#include <algorithm>
#include <functional>
#include <boost/container/small_vector.hpp>
#include "Request.h"
#include "Response.h"

namespace panda { namespace protocol { namespace http {

struct CookieJar: Refcnt {
    using Date = Response::Date;

    struct Cookie : Response::Cookie {
        Cookie() = default;
        Cookie(const string& name, const Response::Cookie& original, const URISP& origin, const Date& now) noexcept;

        const URISP& origin() const noexcept  { return _origin;   }
        const string& name()  const noexcept  { return _name;     }
             bool host_only() const noexcept  { return _host_only;}

        void origin(const URISP& origin) noexcept { _origin = origin;   }
        void name(const string& name)    noexcept { _name = name;       }
        void host_only(bool value)       noexcept { _host_only = value; }


        string to_string () const;
    private:
        bool allowed_by_same_site(const URISP& context_uri, bool top_level) const noexcept;

        string _name;
        URISP _origin;
        bool _host_only = false;
        friend struct CookieJar;
    };

    using IgnorePredicate = bool(const string& name, const Response::Cookie&);
    using ignore_fn  = function<IgnorePredicate>;
    using Cookies = boost::container::small_vector<Cookie, 15>;
    using DomainCookies = std::unordered_map<string, Cookies>;


    CookieJar(const string& data = "");

    void add(const string& name, const Response::Cookie& cookie, const URISP& origin, const Date& now = Date::now()) noexcept;
    Cookies remove(const string& domain = "", const string& name = "", const string& path = "/") noexcept;
    Cookies find(const URISP& request_uri, const URISP& context_uri, const Date& now = Date::now(), bool top_level = false) noexcept;
    Cookies find(const URISP& request_uri, const Date& now = Date::now(), bool top_level = false) noexcept {
        return find(request_uri, request_uri, now, top_level);
    }
    void clear() noexcept { domain_cookies.clear(); }

    void set_ignore(ignore_fn& fn) noexcept { ignore = fn; }

    void collect(const Response& res, const URISP& request_uri, const Date& now = Date::now());
    void populate(Request& request, const URISP& context_uri,  bool top_level = true, const Date& now = Date::now()) noexcept;
    void populate(Request& request,  bool top_level = true, const Date& now = Date::now()) noexcept {
        populate(request, request.uri, top_level, now);
    }

    string to_string(bool include_session = false, const Date& now = Date::now()) const noexcept;
    static std::error_code parse_cookies(const string& data, DomainCookies& dest) noexcept;


    DomainCookies domain_cookies;

private:
    ignore_fn ignore;
    static bool is_subdomain(const string& domain, const string& test_domain) noexcept;

    inline static string canonize(const string& host) noexcept  {
        int add_dot = (host[0] == '.') ? 0 : 1;
        string r(host.size() + add_dot);
        if (add_dot) r[0] = '.';
        std::transform(host.begin(), host.end(), r.begin() + add_dot,[](auto c){ return std::tolower(c); });
        r.length(host.size() + add_dot);
        return r;
    }

    template<typename Fn> void match(const URISP& request_uri, const URISP& context_uri, bool top_level, const Date& now, Fn&& fn) const noexcept;
};

template<typename Fn>
void CookieJar::match(const URISP& request_uri, const URISP& context_uri, bool top_level, const Date& now, Fn&& fn) const noexcept {
    Cookies result;
    auto& path = request_uri->path();
    auto request_domain = canonize(request_uri->host());

    for(auto& pair: domain_cookies) {
        auto& domain = pair.first;
        if (!is_subdomain(domain, request_domain)) continue;

        for(auto& coo: pair.second) {
            auto& p = coo.path();
            bool ignore =  (coo.secure() && !request_uri->secure())
                        || (std::mismatch(p.begin(), p.end(), path.begin()).second != path.end())
                        || (coo.expires() && coo.expires().value() < now)
                        || !coo.allowed_by_same_site(context_uri, top_level)
                        || (coo.host_only() && request_domain != domain);
            // we ignore http-only flag, i.e. provide API-access to that cookie
            if (ignore) continue;
            result.emplace_back(coo);
        }
    }
    std::stable_sort(result.begin(), result.end(), [](auto& a, auto& b) {
        return b.path().length() < a.path().length();
    });
    for(auto& it: result) fn(it);
}

using CookieJarSP = iptr<CookieJar>;



}}}
