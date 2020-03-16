#include "../lib/test.h"

#define TEST(name) TEST_CASE("parse-special-codes: " name, "[parse-special-codes]")

TEST("100 continue") {
    ResponseParser p;
    p.set_context_request(new Request(Method::GET, new URI("/"), Headers().add("Expect", "100-continue")));

    auto result = p.parse("HTTP/1.1 100 Continue\r\n\r\n");
    auto res = result.response;
    CHECK(result.state == State::done);
    CHECK(res->code == 100);
    CHECK(p.context_request());

    result = p.parse("HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n");
    CHECK(result.response != res);
    res = result.response;
    CHECK(result.state == State::done);
    CHECK(res->code == 200);
    CHECK_FALSE(p.context_request());
}

TEST("unexpected 100 continue") {
    ResponseParser p;
    p.set_context_request(new Request());

    auto result = p.parse("HTTP/1.1 100 Continue\r\n\r\n");
    CHECK(result.state == State::error);
    CHECK(result.error == errc::unexpected_continue);
}

TEST("204 no content") {
    ResponseParser p;
    p.set_context_request(new Request());

    auto result = p.parse("HTTP/1.1 204 No Content\r\nConnection: keep-alive\r\n\r\n");
    CHECK(result.state == State::done);
    CHECK(result.response->code == 204);
}

TEST("HEAD response with content length") {
    ResponseParser p;
    p.set_context_request(new Request(Method::HEAD, new URI("/")));
    string raw =
        "HTTP/1.1 200 OK\r\n"
        "Content-Length: 100500\r\n"
        "\r\n";

    auto result = p.parse(raw);
    CHECK(result.state == State::done);
    CHECK(result.response->code == 200);
    CHECK(result.response->headers.get("content-length") == "100500");
}
