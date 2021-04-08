#include "lib/test.h"

#define CHECK_SA(sa, _port, ...) {          \
    CHECK(sa.is_inet4());                   \
    CHECK(sa.port() == _port);              \
    unsigned char tmp[4] = __VA_ARGS__;     \
    CHECK(memcmp(&sa.addr(), tmp, 4) == 0); \
}

TEST_CASE("inet4") {
    SECTION("from ip") {
        SockAddr::Inet4 sa("1.2.3.4", 80);
        CHECK_SA(sa, 80, {1,2,3,4});
        CHECK(sa.ip() == "1.2.3.4");
    }

    SECTION("from addr") {
        SockAddr::Inet4 tmp("1.1.3.3", 80);
        SockAddr::Inet4 sa(tmp.addr(), 400);
        CHECK_SA(sa, 400, {1,1,3,3});
        CHECK(sa.ip() == "1.1.3.3");
    }

    SECTION("from sockaddr_in") {
        SockAddr::Inet4 tmp("255.255.255.255", 65535);
        SockAddr::Inet4 sa(tmp.get());
        CHECK_SA(sa, 65535, {255,255,255,255});
        CHECK(sa.ip() == "255.255.255.255");
    }

    SECTION("invalid ip") {
        CHECK_THROWS(SockAddr::Inet4("123.123.123", 0));
    }

    SECTION("==") {
        CHECK(SockAddr::Inet4("1.2.3.4", 80) == SockAddr::Inet4("1.2.3.4", 80));
        CHECK(SockAddr::Inet4("1.2.3.4", 80) != SockAddr::Inet4("1.2.3.4", 81));
        CHECK(SockAddr::Inet4("1.2.3.4", 80) != SockAddr::Inet4("1.2.3.5", 80));
    }
}
