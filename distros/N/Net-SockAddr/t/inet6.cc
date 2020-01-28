#include "lib/test.h"

#define CHECK_SA(sa, _port, ...) {           \
    CHECK(sa.is_inet6());                    \
    CHECK(sa.port() == _port);               \
    unsigned char tmp[16] = __VA_ARGS__;     \
    CHECK(memcmp(&sa.addr(), tmp, 16) == 0); \
}

TEST_CASE("inet6") {
    SECTION("from ip") {
        SockAddr::Inet6 sa("0:0:0:0:0:ffff:808:808", 80, 1, 2);
        CHECK_SA(sa, 80, {0,0,0,0,0,0,0,0,0,0,255,255,8,8,8,8});
        CHECK(sa.ip() == "::ffff:8.8.8.8");
        CHECK(sa.scope_id() == 1);
        CHECK(sa.flowinfo() == 2);
    }

    SECTION("from addr") {
        SockAddr::Inet6 tmp("::ffff:127.0.0.1", 443);
        SockAddr::Inet6 sa(tmp.addr(), 400, 3, 4);
        CHECK_SA(sa, 400, {0,0,0,0,0,0,0,0,0,0,255,255,127,0,0,1});
        CHECK(sa.ip() == "::ffff:127.0.0.1");
        CHECK(sa.scope_id() == 3);
        CHECK(sa.flowinfo() == 4);
    }

    SECTION("from sockaddr_in") {
        SockAddr::Inet6 tmp("ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff", 65535);
        SockAddr::Inet6 sa(tmp.get());
        CHECK_SA(sa, 65535, {255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255});
        CHECK(sa.ip() == "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff");
    }

    SECTION("localhost") {
        SockAddr::Inet6 sa("::1", 0);
        CHECK(sa.ip() == "::1");
        CHECK_SA(sa, 0, {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1});
        CHECK(sa.scope_id() == 0);
        CHECK(sa.flowinfo() == 0);
    }

    SECTION("==") {
        CHECK(SockAddr::Inet6("::1", 80, 1, 2) == SockAddr::Inet6("::1", 80, 1, 2));
        CHECK(SockAddr::Inet6("::1", 80) != SockAddr::Inet6("::1", 81));
        CHECK(SockAddr::Inet6("::1", 80) != SockAddr::Inet6("::2", 80));
        CHECK(SockAddr::Inet6("::1", 80) != SockAddr::Inet6("::1", 80, 1));
        CHECK(SockAddr::Inet6("::1", 80) != SockAddr::Inet6("::1", 80, 0, 1));
    }

    SECTION("invalid ip") {
        CHECK_THROWS(SockAddr::Inet6("asd:asd", 0));
    }
}
