#include "lib/test.h"

#ifndef _WIN32

TEST_CASE("unix") {
    SECTION("from path") {
        SockAddr::Unix sa("/tmp/jopa");
        CHECK(sa.is_unix());
        CHECK(sa.path() == "/tmp/jopa");
    }

    SECTION("from sockaddr_un") {
        const char* p = "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890";
        SockAddr::Unix tmp(p);
        CHECK(tmp.length() == strlen(p) + SockAddr::PATH_OFFSET + 1);
        SockAddr::Unix sa(tmp.get(), tmp.length());
        CHECK(sa.is_unix());
        CHECK(sa.path() == p);
    }

    SECTION("empty path") {
        const char* p = "";
        SockAddr::Unix tmp(p);
        CHECK(tmp.length() == strlen(p) + SockAddr::PATH_OFFSET + 1);
        SockAddr::Unix sa(tmp.get(), tmp.length());
        CHECK(sa.is_unix());
        CHECK(sa.path() == p);
    }

    SECTION("==") {
        CHECK(SockAddr::Unix("/path") == SockAddr::Unix("/path"));
        CHECK(SockAddr::Unix("/path") != SockAddr::Unix("/path1"));
    }

    SECTION("invalid path") {
        CHECK_THROWS(SockAddr::Unix("/abcdef1234567890/abcdef1234567890/abcdef1234567890/abcdef1234567890/abcdef1234567890/abcdef1234567890/abcdef1234567890/abcdef1234567890"));
    }

    SECTION("assign foreign") {
        SockAddr::Unix me("/tmp/path");
        SockAddr other;

        other.assign_foreign([&me](auto ptr, auto sz){
            memcpy(ptr, me.get(), me.length());
            *sz = me.length();
            return true;
        });
        CHECK(me == other);

        auto fn = [&me](auto ptr, auto* sz){
            memcpy(ptr, me.get(), me.length());
            *sz = 1;
            return true;
        };
        CHECK_THROWS(other.assign_foreign(fn));

        SockAddr::Unix some("/");
        some.assign_foreign([](auto, auto sz){
            *sz = SockAddr::PATH_OFFSET;
            return true;
        });
        CHECK(some.path() == "");
    }
}

#endif
