#include "RequestParser.h"
#include "ResponseParser.h"

namespace panda { namespace protocol { namespace http {

#define ADD_DIGIT(dest) \
    dest *= 10;         \
    dest += *p - '0';
    
#define CURSTR     buffer.substr(mark, p - ps - mark)
#define SAVE(dest) dest = CURSTR

%%{
    machine cookie_rules;
    include rules "Rules.rl";
    
    action mark {
        mark = fpc - ps;
    }
    
    cookie_octet = any - (CTL | WSP | '"' | ',' | ';' | '\\');
    cookie_value = cookie_octet* | ('"' cookie_octet* '"');
    
    

}%%

%%{
    machine cookie_parser;
    include cookie_rules;

    cookie_pair = token >mark %{ cont.emplace_back(CURSTR, string()); }  "=" cookie_value >mark %{ SAVE(cont.back().value); };
    main       := cookie_pair ("; " cookie_pair)* OWS;
    
    write data;
}%%

void RequestParser::parse_cookie (const string& buffer) {
    const char* ps  = buffer.data();
    const char* p   = ps;
    const char* pe  = ps + buffer.size();
    const char* eof = pe;
    int         cs  = cookie_parser_start;
    auto&     cont  = request->cookies.fields;
    size_t mark;
    %% write exec;
}

%%{
    machine set_cookie_parser;
    include cookie_rules;
    
    cookie_pair = token >mark %{ cont.emplace_back(CURSTR, Response::Cookie()); v = &cont.back().value; }  "=" cookie_value >mark %{ SAVE(v->_value); };
    expires_av  = "Expires=" (alnum | SP | ":" | ",")* >mark %{ SAVE(v->_expires); }; # RFC 1123, will be lazy-parsed later by panda::date framework
    max_age_av  = "Max-Age=" ([1-9] digit*) >{ v->_max_age = 0; } ${ ADD_DIGIT(v->_max_age); };
    domain_av   = "Domain=" (alnum | "." | "-")+  >mark %{ SAVE(v->_domain); };
    path_av     = "Path=" ((any - CTL) - ";")+  >mark %{ SAVE(v->_path); };
    secure_av   = "Secure"  %{ v->_secure = true; };
    httponly_av = "HttpOnly"  %{ v->_http_only = true; };
    samesite_av = "SameSite" (
                      ""        %{ v->_same_site = Response::Cookie::SameSite::Strict; }
                    | "=Strict" %{ v->_same_site = Response::Cookie::SameSite::Strict; }
                    | "=Lax"    %{ v->_same_site = Response::Cookie::SameSite::Lax; }
                    | "=None"   %{ v->_same_site = Response::Cookie::SameSite::None; }
                  );
    extension_av = ((any - CTL) - ";")+;
    cookie_av    = expires_av | max_age_av | domain_av | path_av | secure_av | httponly_av | samesite_av | extension_av;
    main        := cookie_pair ("; " cookie_av)*;
    
    write data;
}%%

void ResponseParser::parse_cookie (const string& buffer) {
    const char* ps  = buffer.data();
    const char* p   = ps;
    const char* pe  = ps + buffer.size();
    const char* eof = pe;
    int         cs  = set_cookie_parser_start;
    auto&     cont  = response->cookies.fields;
    size_t mark;
    Response::Cookie* v;
    %% write exec;
}

}}}
