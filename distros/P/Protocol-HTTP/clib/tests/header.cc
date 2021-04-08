#include "test.h"

#define TEST(name) TEST_CASE("header: " name, "[header]")

TEST("case insensitive") {
    Headers h;
    h.add("Aa", "value");
    CHECK(h.get("AA") == "value");
}

TEST("basic") {
    Headers h;
    CHECK(h.length() == 0);
    CHECK(h.get("Content-Length", "default") == "default");

    h.add("field1", "value1");
    CHECK(h.get("field1", "default") == "value1");


    h.set("field1", "value2");
    CHECK(h.get("field1", "default") == "value2");

    h.set("field2", "value2");
    CHECK(h.get("field2", "default") == "value2");
}

TEST("multi") {
    Headers h;

    h.add("key", "hello");
    h.add("Key", "world");

    CHECK(h.get("key") == "world");

    auto r = h.get_multi("key");
    auto it = r.begin();
    CHECK(*it++ == "hello");
    CHECK(*it++ == "world");
    CHECK(it == r.end());
}

TEST("ctor from ilist") {
    auto h = Headers({
        {"key", "val"},
        {"a", "b"},
    });

    CHECK(h.get("key") == "val");
    CHECK(h.get("a") == "b");
}

TEST("operator==") {
    Headers h1, h2;
    for (auto p : {&h1, &h2}) {
        p->add("key", "hello");
        p->add("Key", "world");
        p->add("hi",  "there");
    }

    CHECK(h1 == h2);
    CHECK(h1 == Headers{{"key", "hello"}, {"key", "world"}, {"hi", "there"}});
    CHECK(h1 != Headers{{"key1", "hello"}, {"key", "world"}, {"hi", "there"}});
}

TEST("iequals") {
    CHECK(iequals("a", "A"));
    CHECK(iequals("aa", "aA"));
    CHECK(iequals("Aaa", "aaA"));
    CHECK(iequals("AaaA", "aAAa"));
    CHECK(iequals("Aaaaa", "aaaaA"));
    CHECK(iequals("Aaaaaa", "aaaaaA"));
    CHECK(iequals("Aaaaaaa", "aaaaaaA"));
    CHECK(iequals("Aaaaaaaa", "aaaaaaaA"));
    CHECK(iequals("Aaaaaaaaa", "aaaaaaaaA"));
    CHECK_FALSE(iequals("a", "Transfer-Encoding"));
    CHECK_FALSE(iequals("a", "transfer-encoding"));
}

TEST("builder") {
    auto h = Headers().add("key", "val").add("k", "v");
    CHECK(h == Headers{{"key", "val"}, {"k", "v"}});
}
