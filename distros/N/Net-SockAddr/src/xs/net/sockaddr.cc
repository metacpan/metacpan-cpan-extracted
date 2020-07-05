#include "sockaddr.h"

namespace xs { namespace net {

using panda::net::SockAddr;

static PERL_THREAD_LOCAL HV* s1 = gv_stashpvs("Net::SockAddr::Inet4", GV_ADD);
static PERL_THREAD_LOCAL HV* s2 = gv_stashpvs("Net::SockAddr::Inet6", GV_ADD);
static PERL_THREAD_LOCAL HV* s3 = gv_stashpvs("Net::SockAddr::Unix", GV_ADD);

SockAddr* _in_sockaddr_ptr (SV* arg) {
    if (!SvOK(arg)) return nullptr;
    if (!Sv(arg).is_object_ref()) throw "invalid sockaddr";
    return (panda::net::SockAddr*)SvPVX(SvRV(arg));
}

SockAddr _in_sockaddr (SV* arg) {
    if (!SvOK(arg)) return {};
    if (Sv(arg).is_object_ref()) return *_in_sockaddr_ptr(arg);
    if (!SvPOK(arg) || SvCUR(arg) < sizeof(panda::net::sa_family_t)) throw "invalid sockaddr";

    size_t sz =  (size_t)SvCUR(arg);
    auto sa = (const sockaddr*)SvPVX(arg);
    return SockAddr(sa, sz);
}

Sv _create_sockaddr (const panda::net::SockAddr& var) {
    Stash stash;
    size_t sz = var.length();
    switch (var.family()) {
        case AF_UNSPEC : return Sv::undef;
        case AF_INET   : stash = s1; break;
        case AF_INET6  : stash = s2; break;
        #ifndef _WIN32
        case AF_UNIX   : stash = s3; break;
        #endif
        default: throw "invalid sockaddr family";
    }
    auto base = Simple(panda::string_view(reinterpret_cast<const char*>(&var), sz));
    return stash.bless(base).ref();
}

}}
