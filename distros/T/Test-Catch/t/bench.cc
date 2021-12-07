#include <catch2/catch_test_macros.hpp>
#include <catch2/benchmark/catch_benchmark.hpp>

TEST_CASE("bench", "[.]") {
    BENCHMARK("hello1") {
        uint64_t r = 0;
        for (int i = 0; i < 1000; ++i) {
            auto p = malloc(30000000);
            free(p);
            r += (uint64_t)p;
        }
        return r;
    };
    BENCHMARK("hello2") {
        auto p = malloc(30000000);
        free(p);
        return p;
    };
}
