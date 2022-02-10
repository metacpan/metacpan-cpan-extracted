#include "test.h"
#include <time.h>
#include <catch2/benchmark/catch_benchmark.hpp>

#define TEST(name) TEST_CASE("bench: " name, "[.bench]")

TEST("small parse") {
    ClientParser cp;
    ServerParser sp;
    auto s = cp.connect_request(ConnectRequest::Builder().uri("ws://jopa.ru").build());
    sp.accept(s);
    s = sp.accept_response();
    cp.connect(s);

    auto pl = repeat("x", 50);
    auto bin = sp.start_message().send(pl, IsFinal::YES);
    auto mbin = cp.start_message().send(pl, IsFinal::YES);
    auto zbin = sp.start_message(DeflateFlag::YES).send(pl, IsFinal::YES);
    auto zmbin = cp.start_message(DeflateFlag::YES).send(pl, IsFinal::YES);

    BENCHMARK("unmasked copy") { cp.get_frames(bin); };
    BENCHMARK("masked copy") { sp.get_frames(mbin); };
    
    BENCHMARK_ADVANCED("masked move")(Catch::Benchmark::Chronometer meter) {
        std::vector<string> v;
        for (int i = 0; i < meter.runs(); ++i) { auto s = mbin; s.buf(); v.push_back(std::move(s)); }
        meter.measure([&](int i){ sp.get_frames(std::move(v[i])); });
    };

    BENCHMARK_ADVANCED("masked copy fair")(Catch::Benchmark::Chronometer meter) {
        std::vector<string> v;
        for (int i = 0; i < meter.runs(); ++i) { auto s = mbin; s.buf(); v.push_back(std::move(s)); }
        meter.measure([&](int i){ sp.get_frames(v[i]); });
    };

    BENCHMARK("unmasked deflate") { cp.get_frames(zbin); };
    BENCHMARK("masked deflate") { sp.get_frames(zmbin); };
}

TEST("small compile") {
    ClientParser cp;
    ServerParser sp;
    auto s = cp.connect_request(ConnectRequest::Builder().uri("ws://jopa.ru").build());
    sp.accept(s);
    s = sp.accept_response();
    cp.connect(s);

    auto pl = repeat("x", 50);
    sp.start_message();
    cp.start_message();
    BENCHMARK("unmasked"){ sp.send_frame(pl); };
    BENCHMARK("masked"){ cp.send_frame(pl); };

    sp.send_frame(IsFinal::YES);
    cp.send_frame(IsFinal::YES);
    sp.start_message(DeflateFlag::YES);
    cp.start_message(DeflateFlag::YES);
    
    BENCHMARK_ADVANCED("unmasked deflate")(Catch::Benchmark::Chronometer meter) {
        std::vector<string> v;
        for (int i = 0; i < meter.runs(); ++i) { auto s = pl; s.buf(); v.push_back(std::move(s)); }
        meter.measure([&](int i){ sp.send_frame(v[i]); });
    };
    
    BENCHMARK_ADVANCED("masked deflate")(Catch::Benchmark::Chronometer meter) {
        std::vector<string> v;
        for (int i = 0; i < meter.runs(); ++i) { auto s = pl; s.buf(); v.push_back(std::move(s)); }
        meter.measure([&](int i){ cp.send_frame(v[i]); });
    };
}

TEST("crypt_mask") {
    string src;
    string dst(1000000);
    auto buf = dst.buf();
    
    src = string(30, 'x');
    BENCHMARK("small"){ crypt_mask(src.data(), buf, src.length(), 123456789, 0); };

    src = string(300, 'x');
    BENCHMARK("medium"){ crypt_mask(src.data(), buf, src.length(), 123456789, 0); };
    
    src = string(10000, 'x');
    BENCHMARK("big"){ crypt_mask(src.data(), buf, src.length(), 123456789, 0); };
}