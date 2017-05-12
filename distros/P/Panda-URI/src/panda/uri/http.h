#pragma once
#include <panda/uri/Strict.h>

namespace panda { namespace uri {

class URI::httpX : public Strict {
public:
    httpX () : Strict() {}
    httpX (const string& source, int flags = 0)                     : Strict(source, flags) {}
    httpX (const string& source, const Query& query, int flags = 0) : Strict(source, flags) { add_query(query); }
    httpX (const URI& source)                                       : Strict(source) {}

    using Strict::assign;
    void assign (const string& uristr, const Query& query, int flags = 0) {
        Strict::assign(uristr, flags);
        add_query(query);
    }
};

class URI::https : public httpX {
public:
    https () : httpX() {}
    https (const string& source, int flags = 0)                     : httpX(source, flags)        { strict_scheme(); }
    https (const string& source, const Query& query, int flags = 0) : httpX(source, query, flags) { strict_scheme(); }
    https (const URI& source)                                       : httpX(source)               { strict_scheme(); }
};

class URI::http : public httpX {
public:
    http () : httpX() {}
    http (const string& source, int flags = 0)                     : httpX(source, flags)        { check_my_scheme(); }
    http (const string& source, const Query& query, int flags = 0) : httpX(source, query, flags) { check_my_scheme(); }
    http (const URI& source)                                       : httpX(source)               { check_my_scheme(); }

    using httpX::assign;
    virtual void assign (const URI& source) {
        URI::assign(source);
        check_my_scheme();
    }

    using httpX::scheme;
    virtual void scheme (const string& scheme) {
        URI::scheme(scheme);
        check_my_scheme();
    }

protected:
    virtual void parse (const string& uristr) {
        URI::parse(uristr);
        check_my_scheme();
    }

private:
    void check_my_scheme () { strict_scheme(&typeid(https)); }
};

}}
