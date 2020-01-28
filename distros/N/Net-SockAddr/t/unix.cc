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
        SockAddr::Unix sa(tmp.get());
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
}

#endif
