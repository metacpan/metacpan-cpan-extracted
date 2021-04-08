#include "../test.h"

#define TEST(name) TEST_CASE("compile-message: " name, "[compile-message]")

TEST("headers") {
    RequestSP req;
    SECTION("via header()")  { req = Request::Builder().header("a", "1").header("b", "2").build(); }
    SECTION("via headers()") { req = Request::Builder().headers(Headers().add("a", "1").add("b", "2")).build(); }
    CHECK(req->to_string() ==
        "GET / HTTP/1.1\r\n"
        "a: 1\r\n"
        "b: 2\r\n"
        "\r\n"
    );
}

TEST("headers()+header() - add") {
    auto req = Request::Builder().headers(Headers().add("a", "1").add("b", "2")).header("c", "3").build();
    CHECK(req->to_string() ==
        "GET / HTTP/1.1\r\n"
        "a: 1\r\n"
        "b: 2\r\n"
        "c: 3\r\n"
        "\r\n"
    );
}

TEST("header()+headers() - overwrite") {
    auto req = Request::Builder().header("c", "3").headers(Headers().add("a", "1").add("b", "2")).build();
    CHECK(req->to_string() ==
        "GET / HTTP/1.1\r\n"
        "a: 1\r\n"
        "b: 2\r\n"
        "\r\n"
    );
}

TEST("body") {
    auto req = Request::Builder().body("hello world").build();
    CHECK(req->to_string() ==
        "GET / HTTP/1.1\r\n"
        "Content-Length: 11\r\n"
        "\r\n"
        "hello world"
    );
}

TEST("body doesn't get copied in vector mode") {
    string s = "hello world";
    auto req = Request::Builder().body(s).build();
    auto v = req->to_vector();
    CHECK(v.size() == 2);
    CHECK(v[0] ==
        "GET / HTTP/1.1\r\n"
        "Content-Length: 11\r\n"
        "\r\n"
    );
    CHECK(v[1] == s);
    CHECK(v[1].data() == s.data()); // same pointers
}

TEST("body as object") {
    Body body;
    body.parts.push_back("hello ");
    body.parts.push_back("world");
    auto req = Request::Builder().body(std::move(body)).build();
    CHECK(req->to_string() ==
        "GET / HTTP/1.1\r\n"
        "Content-Length: 11\r\n"
        "\r\n"
        "hello world"
    );
}

TEST("multi-body doesn't get copied in vector mode") {
    Body body;
    string hello = "hello ";
    string world = "world";
    body.parts.push_back(hello);
    body.parts.push_back(world);
    auto req = Request::Builder().body(std::move(body)).build();
    auto v = req->to_vector();
    CHECK(v.size() == 3);
    CHECK(v[0] ==
        "GET / HTTP/1.1\r\n"
        "Content-Length: 11\r\n"
        "\r\n"
    );
    CHECK(v[1] == hello);
    CHECK(v[1].data() == hello.data());
    CHECK(v[2] == world);
    CHECK(v[2].data() == world.data());
}
