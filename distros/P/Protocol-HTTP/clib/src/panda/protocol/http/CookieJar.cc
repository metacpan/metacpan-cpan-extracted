#include "CookieJar.h"

/* I don't think it is needed:

NOTE: For security reasons, many user agents are configured to reject
   Domain attributes that correspond to "public suffixes".  For example,
   some user agents will reject Domain attributes of "com" or "co.uk".
   (See Section 5.3 for more information.)

https://publicsuffix.org/list/

*/

namespace panda { namespace protocol { namespace http {

CookieJar::Cookie::Cookie(const string& name, const Response::Cookie& original, const URISP& origin, const Date& now) noexcept
    : Response::Cookie{original}, _name{name}, _origin{origin}
{
    if (max_age()) {
        auto deadline = now.epoch() + max_age();
        expires(Date(deadline));
        max_age(0);
    }
    /* rfc6265
       If the server omits the Path attribute, the user
       agent will use the "directory" of the request-uri's path component as
       the default value.  (See Section 5.1.4 for more details.)
    */
    if (!path()) {
            auto p = origin->path();
            if (!p) p = "/";
            path(p);
    }

    /* rfc6265
     If the server omits the Domain attribute, the user
     agent will return the cookie only to the origin server.

      WARNING: Some existing user agents treat an absent Domain
      attribute as if the Domain attribute were present and contained
      the current host name.  For example, if example.com returns a Set-
      Cookie header without a Domain attribute, these user agents will
      erroneously send the cookie to www.example.com as well.
    */
    if (!domain()) {
        domain(origin->host());
        _host_only = true;
    }

    auto ss = same_site();
    if (ss == SameSite::None || ss == SameSite::disabled) {
        _origin.reset(); // no need to store origin, discard it early
    }
}

bool CookieJar::Cookie::allowed_by_same_site(const URISP& context_uri, bool top_level) const noexcept {
    bool r = true;
    auto check = [&]() -> bool {
        auto original_domain = canonize(origin()->host());
        auto context_domain  = canonize(context_uri->host());
        return is_subdomain(original_domain, context_domain);
    };
    switch (same_site()) {
    case SameSite::Strict: r = check(); break;
    case SameSite::Lax:    r = top_level || check(); break;
    default:               break;
    }
    return r;
}

string CookieJar::Cookie::to_string () const {
    string r(300);
    size_t i = 0;
    auto push_json = [&](const auto& k, const auto& v) {
        assert(v);
        if (i) r += ", ";
        r += "\"";
        r += k;
        r += "\":\"";
        r += v;
        r += "\"";
        ++i;
    };
    r += "{";
        push_json("key", name());
        push_json("value", value());
        push_json("domain", domain());
        push_json("path", path());
        if (expires())   push_json("expires", panda::to_string(expires().value().epoch()));
        if (secure())    push_json("secure", "1");
        if (http_only()) push_json("http_only", "1");

        const char* same_site_value = nullptr;
        switch (same_site()) {
        case SameSite::Lax:     same_site_value = "L"; break;
        case SameSite::Strict:  same_site_value = "S"; break;
        case SameSite::None:    same_site_value = "N"; break;
        case SameSite::disabled:                       break;
        }
        if (same_site_value) push_json("same_site", same_site_value);
        if (_origin)     push_json("origin", _origin->to_string());
        if (host_only()) push_json("host_only", "1");
    r += "}";
    return r;
}


CookieJar::CookieJar(const string& data) {
    auto result = parse_cookies(data, domain_cookies);
    if (result) throw result.message();
}

void CookieJar::add(const string& name, const Response::Cookie& cookie, const URISP& origin, const Date& now) noexcept {
    auto domain = cookie.domain();
    if (!domain) domain = origin->host();

    string idomain = canonize(domain);

    auto remove_same = [&](bool cleanup) {
        auto& cookies = domain_cookies[idomain];
        for (auto it = cookies.cbegin(); it != cookies.cend();) {
            if (it->name() == name && it->path() == cookie.path()) it = cookies.erase(it);
            else                                                 ++it;
        }
        if (cleanup && cookies.empty()) domain_cookies.erase(idomain);
    };
    auto add = [&](auto& coo) {
        remove_same(false);
        auto& cookies = domain_cookies[idomain];
        cookies.emplace_back(Cookie(name, coo, origin, now));
    };

    if (cookie.session()) { add(cookie); return; }
    if (cookie.expires()) {
        if (*cookie.expires() > now) add(cookie);
        else remove_same(true);
        return;
    }

    add(cookie);
}

CookieJar::Cookies CookieJar::remove(const string& domain, const string& name, const string& path) noexcept {
    CookieJar::Cookies r;
    auto strict   = domain && (domain[0] == '.');
    auto c_domain = domain ?  canonize(domain) : "";
    for(auto it_d = domain_cookies.begin(); it_d != domain_cookies.end(); ) {
        bool d_match = !domain
                    || (strict ? it_d->first == domain : is_subdomain(c_domain, it_d->first));
        auto& cookies = it_d->second;
        if (d_match) {
            for(auto it_c = cookies.begin(); it_c != cookies.end(); ) {
                auto& coo = *it_c;
                auto& p = coo.path();
                bool name_match = !name || coo.name() == name;
                bool path_match = !path || std::mismatch(p.begin(), p.end(), path.begin()).second == path.end();

                if (name_match && path_match) { r.emplace_back(coo);  it_c = cookies.erase(it_c); }
                else                                                ++it_c;
            }
        }
        if (cookies.empty()) it_d = domain_cookies.erase(it_d);
        else               ++it_d;
    }
    return r;
}


bool CookieJar::is_subdomain(const string& domain, const string& test_domain) noexcept {
    assert(domain[0] == '.');
    assert(test_domain[0] == '.');
    // xxx.yyy.com [idomain] (from URI) should pull-in cookies for
    //     yyy.com [domain]
    // do backward search than
    auto r = std::mismatch(domain.rbegin(), domain.rend(), test_domain.rbegin());
    if (r.first != domain.rend()) return false;
    return true;
}


CookieJar::Cookies CookieJar::find(const URISP& uri, const URISP& context_uri, const Date& now, bool top_level) noexcept {
    Cookies result;
    match(uri, context_uri, top_level, now, [&](auto& coo){ result.emplace_back(coo); } );
    return result;
}

void CookieJar::collect(const Response &res, const URISP& request_uri, const Date& now) {
    string req_domain = canonize(request_uri->host());
    for(auto& wrapped_coo: res.cookies) {
        auto& coo = wrapped_coo.value;

        bool skip = (coo.domain() && !is_subdomain(canonize(coo.domain()), req_domain))
                 || (ignore && ignore(wrapped_coo.name, coo));

        if (skip) continue;

        add(wrapped_coo.name, coo, request_uri, now);
    }
}

void CookieJar::populate(Request& request, const URISP& context_uri, bool top_level, const Date& now) noexcept {
    match(request.uri, context_uri, top_level, now, [&](auto& coo) { request.cookies.add(coo.name(), coo.value()); });
}

string CookieJar::to_string(bool include_session, const Date& now) const noexcept {
    string r;
    r += "[\n";
    int i = 0;
    for(auto& pair: domain_cookies) {
        for(auto& coo: pair.second) {
            bool session = coo.session();
            bool add = session ? include_session : (coo.expires().value() > now);
            if (add) {
                if (i++) r+= ",\n";
                r += coo.to_string();
            }
        }
    }
    r += "]";
    return r;
}


}}}
