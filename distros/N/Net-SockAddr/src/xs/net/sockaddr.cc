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
    if (!SvPOK(arg) || SvCUR(arg) < sizeof(sockaddr)) throw "invalid sockaddr";
    auto sa = (const sockaddr*)SvPVX(arg);
    size_t minlen;
    switch (sa->sa_family) {
        case AF_UNSPEC : return {};
        case AF_INET   : minlen = sizeof(sockaddr_in); break;
        case AF_INET6  : minlen = sizeof(sockaddr_in6); break;
        #ifndef _WIN32
        case AF_UNIX   : minlen = sizeof(sockaddr_un); break;
        #endif
        default: throw "invalid sockaddr";
    }
    if (SvCUR(arg) < minlen) throw "invalid sockaddr";
    return sa;
}

Sv _create_sockaddr (const panda::net::SockAddr& var) {
    Stash stash;
    switch (var.family()) {
        case AF_UNSPEC : return Sv::undef;
        case AF_INET   : stash = s1; break;
        case AF_INET6  : stash = s2; break;
        #ifndef _WIN32
        case AF_UNIX   : stash = s3; break;
        #endif
        default: throw "invalid sockaddr family";
    }
    auto base = Simple(panda::string_view(reinterpret_cast<const char*>(&var), sizeof(var)));
    return stash.bless(base).ref();
}

}}
