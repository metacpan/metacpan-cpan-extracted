#include "../test.h"

#define TEST(name) TEST_CASE("compile-chunks: " name, "[compile-chunks]")

TEST("chunked message force version 1.1") {
    auto req = Request::Builder().chunked().http_version(10).build();
    CHECK(req->to_string() ==
        "GET / HTTP/1.1\r\n"
        "Transfer-Encoding: chunked\r\n"
        "\r\n"
    );
}

TEST("final chunk with payload") {
    auto req = Request::Builder().chunked().http_version(10).build();
    string s = "hello world";
    auto c = req->final_chunk(s);
    CHECK(c.size() == 3);
    CHECK(c[0] == "b\r\n");
    CHECK(c[1] == s);
    CHECK(c[1].data() == s.data()); // payload doesn't get copied
    CHECK(c[2] == "\r\n0\r\n\r\n");
}

TEST("generating chunks later") {
    auto req = Request::Builder().chunked().build();

    string s = "hello world";

    auto v = req->make_chunk(s);
    CHECK(v.size() == 3);
    CHECK(v[0] == "b\r\n");
    CHECK(v[1] == s);
    CHECK(v[1].data() == s.data()); // payload doesn't get copied
    CHECK(v[2] == "\r\n");

    CHECK(req->final_chunk() == Message::wrapped_chunk{"", "", "0\r\n\r\n" });
}

TEST("empty chunk is not a final chunk - it gets ignored") {
    auto req = Request::Builder().chunked().build();
    auto v = req->make_chunk("");
    CHECK(v.size() == 3);
    CHECK(v[0] == "");
    CHECK(v[1] == "");
    CHECK(v[2] == "");
}

TEST("chunked message with all content given now") {
    Body body;
    body.parts.push_back("hello ");
    body.parts.push_back("world");
    auto req = Request::Builder().body(std::move(body)).chunked().build();
    CHECK(req->to_string() ==
        "GET / HTTP/1.1\r\n"
        "Transfer-Encoding: chunked\r\n"
        "\r\n"
        "6\r\n"
        "hello \r\n"
        "5\r\n"
        "world\r\n"
        "0\r\n"
        "\r\n"
    );
}

TEST("chunks in vector mode doesn't get copied") {
    Body body;
    string hello = "hello ";
    string world = "world";
    body.parts.push_back(hello);
    body.parts.push_back(world);
    auto req = Request::Builder().body(std::move(body)).chunked().build();

    auto v = req->to_vector();

    CHECK(v.size() == 8); // 1 for headers, 3 per each chunk (chunk header, chunk body, chunk end), 1 for final chunk

    CHECK(v[0] ==
        "GET / HTTP/1.1\r\n"
        "Transfer-Encoding: chunked\r\n"
        "\r\n"
    );

    CHECK(v[1] == "6\r\n");
    CHECK(v[2] == hello);
    CHECK(v[2].data() == hello.data());
    CHECK(v[3] == "\r\n");

    CHECK(v[4] == "5\r\n");
    CHECK(v[5] == world);
    CHECK(v[5].data() == world.data());
    CHECK(v[6] == "\r\n");

    CHECK(v[7] == "0\r\n\r\n");
}

TEST("multiple to_string/vector calls doesn't pollute message") {
    auto req = Request::Builder().body("hello").chunked().build();
    auto s1 = req->to_string();
    CHECK(s1 == req->to_string());
}
