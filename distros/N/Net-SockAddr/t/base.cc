#include "lib/test.h"

TEST_CASE("base") {

    SECTION("empty ctor") {
        SockAddr sa;
        CHECK(sa.family() == AF_UNSPEC);
    }

    SECTION("copying values") {
        auto sa = get_empty_sa();
        CHECK(sa.family() == AF_UNSPEC);
    }

    SECTION("copy ctor") {
        SECTION("from unspec") {
            SockAddr tmp;
            CHECK(tmp.length() > 0);
            SockAddr sa = tmp;
            CHECK(sa.family() == AF_UNSPEC);
        }
        SECTION("from inet4") {
            SockAddr sa = (SockAddr)SockAddr::Inet4("10.10.10.2", 1234);
            CHECK(sa.is_inet4());
            CHECK(sa.inet4().ip() == "10.10.10.2");
        }
        SECTION("from inet6") {
            SockAddr sa = (SockAddr)SockAddr::Inet6("::1", 1234);
            CHECK(sa.is_inet6());
            CHECK(sa.inet6().ip() == "::1");
        }
        #ifndef _WIN32
        SECTION("from unix") {
            SockAddr sa = (SockAddr)SockAddr::Unix("/path");
            CHECK(sa.is_unix());
            CHECK(sa.unix().path() == "/path");
        }
        #endif
    }

    SECTION("invalid ctor") {
        SockAddr me = (SockAddr)SockAddr::Inet4("10.10.10.2", 1234);
        CHECK_THROWS(SockAddr(me.get(), 1));
    }

    SECTION("==") {
        CHECK(SockAddr::Inet4("127.0.0.1", 10) != SockAddr::Inet6("::1", 10));
    }

    SECTION("=") {
        SockAddr sa = (SockAddr)SockAddr::Inet4("10.10.10.2", 1234);
        SockAddr sa2;
        sa2 = sa;
        CHECK(sa2 == sa);
    }


    SECTION("bool") {
        SockAddr sa;
        CHECK(!sa);
        sa = SockAddr::Inet4("0.0.0.0", 0);
        CHECK(sa);
    }

    SECTION("ip/port/length") {
        SockAddr sa;
        CHECK(sa.ip() == "");
        CHECK(sa.port() == 0);
        CHECK(sa.length() > 0);

        sa = SockAddr::Inet4("127.0.0.1", 10);
        CHECK(sa.ip() == "127.0.0.1");
        CHECK(sa.port() == 10);
        CHECK(sa.length() == sizeof(sockaddr_in));

        sa = SockAddr::Inet6("::1", 20);
        CHECK(sa.ip() == "::1");
        CHECK(sa.port() == 20);
        CHECK(sa.length() == sizeof(sockaddr_in6));

        #ifndef _WIN32
        sa = SockAddr::Unix("/path");
        CHECK(sa.length() == 8);
        CHECK_THROWS(sa.ip());
        CHECK_THROWS(sa.port());
        #endif
    }

    SECTION("assign_foreign") {
        SockAddr me = (SockAddr)SockAddr::Inet4("10.10.10.2", 1234);
        SockAddr other;

        other.assign_foreign([&me](auto ptr, auto sz){
            memcpy(ptr, me.get(), me.length());
            *sz = me.length();
            return true;
        });
        CHECK(me == other);

        auto fn = [](auto ptr, auto* sz){
            auto buff = reinterpret_cast<char*>(ptr);
            // garbage
            *buff++ = 99;
            *buff++ = 99;
            *buff++ = 99;
            *buff++ = 99;
            *sz = 3;
            return true;
        };
        CHECK_THROWS(other.assign_foreign(fn));
    }

}
