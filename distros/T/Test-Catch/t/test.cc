#include <catch.hpp>

TEST_CASE("test1", "[tag1]") {
    REQUIRE(1);
    REQUIRE(1);
    REQUIRE(1);
}

TEST_CASE("test2", "[tag1]") {
    REQUIRE(1);
    SECTION("subtest1") {
        REQUIRE(1);
        REQUIRE(1);
    }
    SECTION("subtest2") {
        REQUIRE(1);
    }
    REQUIRE(1);
}

TEST_CASE("test3", "[tag2]") {
    REQUIRE(1);
}

TEST_CASE("test4", "[tag1][tag2]") {
    REQUIRE(1);
}
