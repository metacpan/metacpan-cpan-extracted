#include  "../test.h"

#define TEST(name) TEST_CASE("server-accept_error: " name, "[server-accept_error]")

using namespace Catch::Matchers;

ConnectRequestSP bad_http (string from, string to) {
    ServerParser p;
    auto vdata = accept_packet();
    regex_replace(vdata[0], from, to);
    ConnectRequestSP creq;
    for (auto& chunk : vdata) {
        creq = p.accept(chunk);
        if (p.accept_parsed()) break;
    }
    CHECK(creq);
    CHECK(creq->error());
    CHECK(p.accept_parsed());
    CHECK(!p.accepted());
    CHECK(!p.established());
    auto ans = p.accept_error();
    CHECK_THAT(ans, ContainsSubstring("HTTP/1.1 400 Bad Request\r\n"));
    return creq;
}

TEST("bad http") {
    auto creq = bad_http("GET", "POST");
    CHECK(creq->headers.get("connection") == "Upgrade"); // parsed
    bad_http("HTTP/1.1", "Error");
}

TEST("bad websocket http") {
    ServerParser p;
    auto data = accept_packet_s();
    regex_replace(data, "Upgrade: websocket\r\n", "Upgrade: fuckoff\r\n");
    auto creq = p.accept(data);
    CHECK(creq);
    CHECK(creq->error());
    CHECK(creq->headers.get("connection") == "Upgrade");
    CHECK(p.accept_parsed());
    CHECK(!p.accepted());
    auto ans = p.accept_error();
    CHECK_THAT(ans, ContainsSubstring("HTTP/1.1 400 Bad Request\r\n"));
}

TEST("bad websocket version") {
    ServerParser p;
    auto data = accept_packet_s();
    regex_replace(data, "(Sec-WebSocket-Version:) \\d+\r\n", "$1 999\r\n");
    auto creq = p.accept(data);
    CHECK(creq);
    CHECK(creq->error());
    CHECK(creq->headers.get("connection") == "Upgrade");
    CHECK(p.accept_parsed());
    CHECK(!p.accepted());
    auto ans = p.accept_error();
    CHECK_THAT(ans, ContainsSubstring("HTTP/1.1 426 Upgrade Required\r\n"));
    CHECK_THAT(ans, ContainsSubstring("Sec-WebSocket-Version: 13\r\n"));
}

TEST("custom error override ignored when request error") {
    ServerParser p;
    auto data = accept_packet_s();
    regex_replace(data, "Upgrade: websocket\r\n", "Upgrade: fuckoff\r\n");
    p.accept(data);
    CHECK(p.accept_parsed());
    CHECK(!p.accepted());
    protocol::http::ResponseSP eres = new protocol::http::Response();
    eres->code = 404;
    auto ans = p.accept_error(eres);
    CHECK_THAT(ans, ContainsSubstring("HTTP/1.1 400 Bad Request\r\n"));
}

TEST("custom error") {
    ServerParser p;
    auto data = accept_packet_s();
    p.accept(data);
    CHECK(p.accept_parsed());
    CHECK(p.accepted());
    protocol::http::ResponseSP eres = new protocol::http::Response();
    eres->code = 404;
    eres->message = "Hello World";
    eres->headers = Headers{
        {"abc", "1"},
        {"def", "2"},
    };
    auto ans = p.accept_error(eres);
    CHECK_THAT(ans, ContainsSubstring("HTTP/1.1 404 Hello World\r\n"));
    CHECK_THAT(ans, ContainsSubstring("abc: 1\r\n"));
    CHECK_THAT(ans, ContainsSubstring("def: 2\r\n"));
    CHECK_THAT(ans, MatchesRe("\r\n404 Hello World$"));
}

TEST("custom error with body") {
    ServerParser p;
    auto data = accept_packet_s();
    p.accept(data);
    CHECK(p.accept_parsed());
    CHECK(p.accepted());
    protocol::http::ResponseSP eres = new protocol::http::Response();
    eres->code = 404;
    eres->message = "Hello World";
    eres->body = "Fuck You";
    auto ans = p.accept_error(eres);
    CHECK_THAT(ans, ContainsSubstring("HTTP/1.1 404 Hello World\r\n"));
    CHECK_THAT(ans, MatchesRe("\r\nFuck You$"));
}
