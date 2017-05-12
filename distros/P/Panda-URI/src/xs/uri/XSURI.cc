#include <xs/uri/XSURI.h>
#include <unordered_map>
#include <xs/lib.h>

namespace xs { namespace uri {

using xs::lib::sv2string;
using panda::uri::Query;

static std::unordered_map<string, SV*> uri_class_map;

void XSURIWrapper::register_perl_scheme (pTHX_ const string& scheme, const string_view& perl_class) {
    uri_class_map[scheme] = newSVpvn_share(perl_class.data(), perl_class.length(), 0);
}

SV* XSURIWrapper::get_perl_class (pTHX_ const URI* uri) {
    static SV* default_perl_class = newSVpvs_share("Panda::URI");
    auto it = uri_class_map.find(uri->scheme());
    if (it == uri_class_map.end()) return default_perl_class;
    else return it->second;
}

static void hv2query (pTHX_ HV* hvquery, Query* query) {
    XS_HV_ITER(hvquery, {
        SV* valueSV = HeVAL(he);
        string key(HeKEY(he), HeKLEN(he));
        if (SvROK(valueSV) && SvTYPE(SvRV(valueSV)) == SVt_PVAV) {
            XS_AV_ITER((AV*)SvRV(valueSV), {
                string value;
                if (elem && SvOK(elem)) {
                    STRLEN vlen;
                    char* vstr = SvPV(elem, vlen);
                    value.assign(vstr, vlen);
                }
                query->emplace(key, value);
            });
        }
        else {
            string value;
            if (SvOK(valueSV)) {
                STRLEN vlen;
                char* vstr = SvPV(valueSV, vlen);
                value.assign(vstr, vlen);
            }
            query->emplace(key, value);
        }
    });
}

void XSURIWrapper::add_query_args (pTHX_ URI* uri, SV** sp, I32 items, bool replace) {
    if (items == 1) {
        if (SvROK(*sp)) {
            SV* var = SvRV(*sp);
            if (SvTYPE(var) == SVt_PVHV) add_query_hv(aTHX_ uri, (HV*)var, replace);
        }
        else if (replace) uri->query(sv2string(aTHX_ *sp));
        else              uri->add_query(sv2string(aTHX_ *sp));
    }
    else {
        SV** spe = sp + items;
        for (; sp < spe; sp += 2) add_param(aTHX_ uri, sv2string(aTHX_ *sp), *(sp+1), replace);
    }
}

void XSURIWrapper::add_param (pTHX_ URI* uri, string key, SV* val, bool replace) {
    if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
        if (replace) uri->query().erase(key);
        XS_AV_ITER_NE((AV*)SvRV(val), {
            uri->query().emplace(key, sv2string(aTHX_ elem));
        });
    }
    else if (replace) uri->param(key, sv2string(aTHX_ val));
    else uri->query().emplace(key, sv2string(aTHX_ val));
}

void XSURIWrapper::add_query_hv (pTHX_ URI* uri, HV* hash, bool replace) {
    if (replace) {
        Query query;
        hv2query(aTHX_ (HV*)hash, &query);
        uri->query(query);
    }
    else XS_HV_ITER(hash, {
        add_param(aTHX_ uri, string(HeKEY(he), HeKLEN(he)), HeVAL(he));
    });
}

void XSURIWrapper::sync_query_hv (pTHX) const {
    HV* hash;
    if (query_cache) {
        hash = (HV*) SvRV(query_cache);
        hv_clear(hash);
    }
    else {
        hash = newHV();
        query_cache = newRV_noinc((SV*)hash);
    }

    const URI* uri = this->uri;
    Query::const_iterator end = uri->query().cend();
    for (Query::const_iterator it = uri->query().cbegin(); it != end; ++it)
        hv_store(hash, it->first.data(), it->first.length(), newSVpvn(it->second.data(), it->second.length()), 0);

    query_cache_rev = uri->query().rev;
}

}}
