#pragma once
#include <panda/string.h>
#include <panda/string_view.h>
#include <utility>
#ifdef _WIN32
    #include <winsock2.h>
    #include <Ws2tcpip.h>
#else
    #include <netinet/in.h>
    #include <sys/socket.h>
    #include <sys/un.h>
#endif

namespace panda { namespace net {

static const int IP4_MAX_ADDRSTRLEN = 16;
static const int IP6_MAX_ADDRSTRLEN = 46;

using sa_family_t = decltype(std::declval<sockaddr>().sa_family);

struct SockAddr {
    struct Inet4;
    struct Inet6;

    SockAddr () { sa.sa_family = AF_UNSPEC; }

    SockAddr (const sockaddr* sa);
    SockAddr (const sockaddr_in*  sa) : sa4(*sa) {}
    SockAddr (const sockaddr_in6* sa) : sa6(*sa) {}

    SockAddr (const SockAddr& oth) : SockAddr(&oth.sa) {}

    sa_family_t family () const { return sa.sa_family; }

    bool is_inet4 () const { return family() == AF_INET; }
    bool is_inet6 () const { return family() == AF_INET6; }

    Inet4& inet4 () const { return *((Inet4*)this); }
    Inet6& inet6 () const { return *((Inet6*)this); }

    const sockaddr* get () const { return &sa; }
    sockaddr*       get ()       { return &sa; }

    bool operator== (const SockAddr& oth) const;
    bool operator!= (const SockAddr& oth) const { return !operator==(oth); }

    explicit
    operator bool () const { return sa.sa_family != AF_UNSPEC; }

    string   ip     () const;
    uint16_t port   () const;
    size_t   length () const;

    #ifndef _WIN32

    struct Unix;

    SockAddr (const sockaddr_un* sa) : sau(*sa) {}

    bool is_unix () const { return family() == AF_UNIX; }

    Unix& unix () const { return *((Unix*)this); }

    #endif

protected:
    union {
        sockaddr     sa;
        sockaddr_in  sa4;
        sockaddr_in6 sa6;
        #ifndef _WIN32
        sockaddr_un  sau;
        #endif
    };
};

std::ostream& operator<< (std::ostream&, const SockAddr&);

struct SockAddr::Inet4 : SockAddr {
    static const in_addr addr_any;
    static const in_addr addr_loopback;
    static const in_addr addr_broadcast;
    static const in_addr addr_none;
    static const Inet4   sa_any;
    static const Inet4   sa_loopback;

    Inet4 (const sockaddr_in* sa) : SockAddr(sa)        {}
    Inet4 (const Inet4& oth)      : SockAddr(oth.get()) {}

    Inet4 (const string_view& ip, uint16_t port);
    Inet4 (const in_addr& addr, uint16_t port);

    const in_addr& addr () const { return sa4.sin_addr; }
    in_addr&       addr ()       { return sa4.sin_addr; }

    const sockaddr_in* get () const { return &sa4; }
    sockaddr_in*       get ()       { return &sa4; }

    uint16_t port () const { return ntohs(sa4.sin_port); }
    string   ip   () const;
};

struct SockAddr::Inet6 : SockAddr {
    static const in6_addr addr_any;
    static const in6_addr addr_loopback;
    static const Inet6    sa_any;
    static const Inet6    sa_loopback;

    Inet6 (const sockaddr_in6* sa) : SockAddr(sa)        {}
    Inet6 (const Inet6& oth)       : SockAddr(oth.get()) {}

    Inet6 (const string_view& ip, uint16_t port, uint32_t scope_id = 0, uint32_t flowinfo = 0);
    Inet6 (const in6_addr& addr, uint16_t port, uint32_t scope_id = 0, uint32_t flowinfo = 0);

    const in6_addr& addr () const { return sa6.sin6_addr; }
    in6_addr&       addr ()       { return sa6.sin6_addr; }

    const sockaddr_in6* get () const { return &sa6; }
    sockaddr_in6*       get ()       { return &sa6; }

    string   ip       () const;
    uint16_t port     () const { return ntohs(sa6.sin6_port); }
    uint32_t scope_id () const { return sa6.sin6_scope_id; }
    uint32_t flowinfo () const { return ntohl(sa6.sin6_flowinfo); }
};

#ifndef _WIN32

struct SockAddr::Unix : SockAddr {
    Unix (const sockaddr_un* sa) : SockAddr(sa)        {}
    Unix (const Unix& oth)       : SockAddr(oth.get()) {}

    Unix (const string_view& path);

    string_view path () const { return (char*)sau.sun_path; }

    const sockaddr_un* get () const { return &sau; }
    sockaddr_un*       get ()       { return &sau; }
};

#endif

}}
