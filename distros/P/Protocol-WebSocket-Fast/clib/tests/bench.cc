#include "test.h"
#include <time.h>

#define TEST(name) TEST_CASE("bench: " name, "[.bench]")

#ifndef BENCHMARK // stub if benchmarking is disabled
    #define BENCHMARK(name) [&]()
#endif

double curtime () {
    struct timespec ts;
    int status = clock_gettime(CLOCK_REALTIME, &ts);
    assert(status == 0);
    return (double)ts.tv_sec + (double)ts.tv_nsec / 1000000000;
}

template <class T>
void bench (string name, int cnt, T&& cb) {
    auto start = curtime();
    for (int i = 0; i < cnt; ++i) cb();
    auto took = curtime() - start;
    int speed = (took == 0) ? 0 : (cnt / took);
    printf("%s\t\t: took %.3fs, speed %d\n", name.c_str(), took, speed);
}

template <class T, class INIT>
void bench (string name, int cnt, T&& cb, INIT&& init) {
    std::vector<decltype(init())> v;
    v.reserve(cnt);
    for (int i = 0; i < cnt; ++i) v.emplace_back(init());
    auto start = curtime();
    for (int i = 0; i < cnt; ++i) cb(std::move(v[i]));
    auto took = curtime() - start;
    int speed = (took == 0) ? 0 : (cnt / took);
    printf("%s\t\t: took %.3fs, speed %d\n", name.c_str(), took, speed);
}

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

    bench("unmasked copy", 10 * 1000 * 1000, [&]{ cp.get_frames(bin); });
    bench("masked copy", 10 * 1000 * 1000, [&]{ sp.get_frames(mbin); });
    bench("masked move", 10 * 1000 * 1000, [&](string&& s){ sp.get_frames(std::move(s)); }, [&]{ string ret = mbin; ret.buf(); return ret; });
    bench("masked copy fair", 10 * 1000 * 1000, [&](string&& s){ sp.get_frames(s); }, [&]{ string ret = mbin; ret.buf(); return ret; });

    bench("unmasked deflate", 10 * 1000 * 1000, [&]{ cp.get_frames(zbin); });
    bench("masked deflate", 10 * 1000 * 1000, [&]{ sp.get_frames(zmbin); });
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
    bench("unmasked", 10 * 1000 * 1000, [&]{ sp.send_frame(pl); });
    bench("masked", 10 * 1000 * 1000, [&]{ cp.send_frame(pl); });

    sp.send_frame(IsFinal::YES);
    cp.send_frame(IsFinal::YES);
    sp.start_message(DeflateFlag::YES);
    cp.start_message(DeflateFlag::YES);

    bench("unmasked deflate", 1 * 1000 * 1000, [&](string&& s){ sp.send_frame(s); }, [&]{ string ret = pl; ret.buf(); return ret; });
    bench("masked deflate", 1 * 1000 * 1000, [&](string&& s){ cp.send_frame(s); }, [&]{ string ret = pl; ret.buf(); return ret; });
}
