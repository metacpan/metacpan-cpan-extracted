#include "CookieJar.h"

namespace panda { namespace protocol { namespace http {

#define CURSTR     (buffer.substr(mark, p - ps - mark))

%%{
    machine jar_parser;
    Q = '"';
    N = "\n";

    action mark {
        mark = fpc - ps;
    }

    action origin {
        v.origin(new URI(CURSTR));
    }

    action expires {
        string str(CURSTR);
        uint64_t val;
        auto res = panda::from_chars(str.data(), str.data() + str.size(), val);
        if (res.ec == std::errc()) {
            v.expires(Date(val));
        }
    }

    action same_site {
        auto s(CURSTR);
        SameSite val{SameSite::disabled};
        if      (s == "N") val = SameSite::None;
        else if (s == "S") val = SameSite::Strict;
        else if (s == "L") val = SameSite::Lax;
        v.same_site(val);
    }

    action push_cookie {
        string idomain = canonize(v.domain());
        auto& cookies = dest[idomain];
        cookies.emplace_back(std::move(v));
        v = CookieJar::Cookie();
    }

    key_av       = Q "key"       Q ":" Q (any - Q)+ >mark %{ v.name(CURSTR);    } Q;
    value_av     = Q "value"     Q ":" Q (any - Q)+ >mark %{ v.value(CURSTR);   } Q;
    domain_av    = Q "domain"    Q ":" Q (any - Q)+ >mark %{ v.domain(CURSTR);  } Q;
    path_av      = Q "path"      Q ":" Q (any - Q)+ >mark %{ v.path(CURSTR);    } Q;
    host_only_av = Q "host_only" Q ":" Q (any - Q)+ >mark %{ v.host_only(true); } Q;
    secure_av    = Q "secure"    Q ":" Q (any - Q)+ >mark %{ v.secure(true);    } Q;
    http_only_av = Q "http_only" Q ":" Q (any - Q)+ >mark %{ v.http_only(true); } Q;
    expires_av   = Q "expires"   Q ":" Q (any - Q)+ >mark %expires                Q;
    same_site_av = Q "same_site" Q ":" Q (any - Q)+ >mark %same_site              Q;
    origin_av    = Q "origin"    Q ":" Q (any - Q)+ >mark %origin                 Q;
    cookie_val   = key_av | value_av | domain_av | path_av | host_only_av |secure_av | http_only_av | expires_av | same_site_av | origin_av;
    cookie       = "{" cookie_val (", " cookie_val)*  %push_cookie "}";
    cookies_coll = "[" N (cookie (",\n" cookie)*)? N? "]";
    main        := cookies_coll;

    write data;
}%%

std::error_code CookieJar::parse_cookies(const string& buffer, DomainCookies& dest) noexcept {
    using SameSite = Response::Cookie::SameSite;

    const char* ps  = buffer.data();
    const char* p   = ps;
    const char* pe  = ps + buffer.size();
    int         cs  = jar_parser_start;
    size_t mark;
    CookieJar::Cookie v;

    %% write exec;

    if (p == pe) return {};
    else return make_error_code(errc::corrupted_cookie_jar);
}

}}}
