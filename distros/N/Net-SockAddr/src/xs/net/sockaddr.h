#pragma once
#include <xs.h>
#include <panda/net/sockaddr.h>

namespace xs { namespace net {
    panda::net::SockAddr* _in_sockaddr_ptr (SV* arg);
    panda::net::SockAddr  _in_sockaddr     (SV* arg);
    Sv _create_sockaddr (const panda::net::SockAddr& var);
}}


namespace xs {
    template <class TYPE> struct Typemap<panda::net::SockAddr*, TYPE> : TypemapBase<panda::net::SockAddr*, TYPE> {
        static panda::net::SockAddr* in (SV* arg) { return xs::net::_in_sockaddr_ptr(arg); }
        static Sv out (const panda::net::SockAddr* var, const Sv& = {}) {
            if (!var) return Sv::undef;
            return xs::net::_create_sockaddr(*var);
        }
    };

    template <> struct Typemap<panda::net::SockAddr> : TypemapBase<panda::net::SockAddr> {
        static panda::net::SockAddr in (SV* arg) { return xs::net::_in_sockaddr(arg); }
        static Sv out (const panda::net::SockAddr& var, const Sv& = {}) { return xs::net::_create_sockaddr(var); }
    };

    template <> struct Typemap<const panda::net::SockAddr&> : Typemap<panda::net::SockAddr> {};
}
