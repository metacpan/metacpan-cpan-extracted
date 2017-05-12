#pragma once
#include <xs/xs.h>
#include <panda/string.h>
#include <panda/uri/URI.h>
#include <panda/uri/ftp.h>
#include <panda/uri/http.h>
#include <panda/string_view.h>

namespace xs { namespace uri {

using panda::string;
using std::string_view;
using panda::uri::URI;
using panda::uri::Query;

typedef URI URIx;

class XSURIWrapper {
public:
    URI*             uri;
    mutable SV*      query_cache;
    mutable uint32_t query_cache_rev;

    XSURIWrapper (URI* uri) : uri(uri), query_cache(NULL), query_cache_rev(0) {
        uri->retain();
    }

    void sync_query_hv (pTHX) const;

    SV* query_hv (pTHX) const {
        if (!query_cache || query_cache_rev != uri->query().rev) sync_query_hv(aTHX);
        return query_cache;
    }

    ~XSURIWrapper () {
        dTHX;
        if (query_cache) SvREFCNT_dec(query_cache);
        uri->release();
    }

    static void register_perl_scheme (pTHX_ const string& scheme, const string_view& perl_class);
    static SV*  get_perl_class       (pTHX_ const URI* uri);

    static void add_query_args (pTHX_ URI* uri, SV** sp, I32 items, bool replace = false);
    static void add_query_hv   (pTHX_ URI* uri, HV*, bool replace = false);
    static void add_param      (pTHX_ URI* uri, string key, SV* val, bool replace = false);

private:
    XSURIWrapper (const XSURIWrapper&) {}
    XSURIWrapper& operator= (const XSURIWrapper&) { return *this; }
};

class XSURI : public xs::XSBackref, public URI {
public:
    XSURI (const string& source, int flags = 0) : URI(source, flags) {}
    XSURI (const URI& source)                   : URI(source)        {}
    class ftp;
    class http;
    class https;
};

class XSURI::https : public xs::XSBackref, public URI::https {
public:
    https () : URI::https() {}
    https (const string& source, int flags = 0)                     : URI::https(source, flags)        {}
    https (const string& source, const Query& query, int flags = 0) : URI::https(source, query, flags) {}
    https (const URI& source)                                       : URI::https(source)               {}
};

class XSURI::http : public xs::XSBackref, public URI::http {
public:
    http () : URI::http() {}
    http (const string& source, int flags = 0)                     : URI::http(source, flags)        {}
    http (const string& source, const Query& query, int flags = 0) : URI::http(source, query, flags) {}
    http (const URI& source)                                       : URI::http(source)               {}
};

class XSURI::ftp : public xs::XSBackref, public URI::ftp {
public:
    ftp () : URI::ftp() {}
    ftp (const string& source, int flags = 0) : URI::Strict(source, flags), URI::ftp(source, flags) {}
    ftp (const URI& source)                   : URI::Strict(source),        URI::ftp(source)        {}
};

}}
