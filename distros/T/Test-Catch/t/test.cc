#include <catch.hpp>

TEST_CASE("a", "[single]") {
    REQUIRE(1);
}

TEST_CASE("b", "[single]") {
    REQUIRE(1);
}

TEST_CASE("c", "[single][s3]") {
    REQUIRE(1);
    REQUIRE(1);
    REQUIRE(1);
}

TEST_CASE("d", "[multi]") {
    SECTION("subtest1") {
        REQUIRE(1);
        REQUIRE(1);
    }
    SECTION("subtest2") {
        REQUIRE(1);
    }
}

TEST_CASE("e", "[multi]") {
    static int cnt = 0;
    ++cnt;
    REQUIRE(cnt);
    SECTION("subtest1") {
        SECTION("sst1") {
            REQUIRE(cnt);
        }
        SECTION("sst2") {
            REQUIRE(cnt);
        }
    }
    SECTION("subtest2") {
        REQUIRE(cnt);
        REQUIRE(cnt);
    }
    REQUIRE(cnt);
}
