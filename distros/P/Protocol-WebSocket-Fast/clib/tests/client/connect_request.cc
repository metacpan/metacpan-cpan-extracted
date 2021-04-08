#include "../test.h"
#include <regex>

#define TEST(name) TEST_CASE("client-connect-request: " name, "[client-connect-request]")

using namespace Catch::Matchers;

TEST("parser create") {
    ClientParser p;
    CHECK(!p.established());
}

TEST("default request") {
    ClientParser p;
    p.no_deflate();
    auto req = make_iptr<ConnectRequest>();
    req->uri = new URI("ws://crazypanda.ru:4321/path?a=b");
    req->ws_protocol("fuck");
    req->ws_extensions({
        {"permessage-deflate", {{"client_max_window_bits" , ""}}},
    });
    req->ws_version(12);
    req->headers = Headers({
        {"Accept-Encoding", "gzip, deflate, sdch"},
        {"Origin",          "http://www.crazypanda.ru"},
        {"Cache-Control",   "no-cache"},
        {"User-Agent",      "PWS-Test"},
    });

    auto str = p.connect_request(req);
    CHECK_THAT(str, StartsWith("GET /path?a=b HTTP/1.1\r\n"));
    CHECK_THAT(str, Contains("Sec-WebSocket-Protocol: fuck\r\n"));
    CHECK_THAT(str, Contains("Sec-WebSocket-Version: 12\r\n"));
    CHECK_THAT(str, MatchesRe("Sec-WebSocket-Key: (.+)\r\n"));
    CHECK_THAT(str, Contains("Sec-WebSocket-Extensions: permessage-deflate; client_max_window_bits\r\n"));
    CHECK_THAT(str, Contains("Connection: Upgrade\r\n"));
    CHECK_THAT(str, Contains("Upgrade: websocket\r\n"));
    CHECK_THAT(str, Contains("Origin: http://www.crazypanda.ru\r\n"));
    CHECK_THAT(str, Contains("Accept-Encoding: gzip, deflate, sdch\r\n"));
    CHECK_THAT(str, Contains("Cache-Control: no-cache\r\n"));
    CHECK_THAT(str, Contains("User-Agent: PWS-Test\r\n"));
    CHECK_THAT(str, Contains("Host: crazypanda.ru\r\n"));

    CHECK(!p.established());

    CHECK_THROWS_AS(p.connect_request(req), Error);
}

TEST("default values") {
    ClientParser p;
    auto str = p.connect_request(ConnectRequest::Builder().uri("ws://crazypanda.ru:4321/path?a=b").build());
    CHECK_THAT(str, StartsWith("GET /path?a=b HTTP/1.1\r\n"));
    CHECK_THAT(str, Contains("Sec-WebSocket-Version: 13\r\n"));
    CHECK_THAT(str, Contains("Sec-WebSocket-Extensions: permessage-deflate; client_max_window_bits=15; server_max_window_bits=15\r\n"));
    CHECK_THAT(str, !Contains("Sec-Websocket-Protocol: \r\n"));
}

TEST("custom ws_key") {
    ClientParser p;
    auto str = p.connect_request(ConnectRequest::Builder()
        .uri(new URI("ws://crazypanda.ru:4321/path?a=b"))
        .ws_key("suka")
        .build()
    );
    CHECK_THAT(str, Contains("Sec-WebSocket-Key: suka\r\n"));
}

TEST("empty relative url") {
    ClientParser p;
    auto str = p.connect_request(ConnectRequest::Builder().uri("wss://crazypanda.ru").build());
    CHECK_THAT(str, StartsWith("GET / HTTP/1.1\r\n"));
}

TEST("server parser accepts connect request") {
    ClientParser p;
    ServerParser sp;
    auto str = p.connect_request(ConnectRequest::Builder().uri("ws://crazypanda.ru/path?a=b").build());
    str = string(std::regex_replace((std::string)str, std::regex("websocket"), "WebSocket")); // check case insensitive
    auto req = sp.accept(str);
    CHECK(sp.accepted());
    REQUIRE(req);
    CHECK_FALSE(req->error());
    CHECK(req->ws_version() == 13);
    CHECK(req->uri->to_string() == "/path?a=b");
}

TEST("no host in uri") {
    ClientParser p;
    auto req = ConnectRequest::Builder().uri("ws:path?a=b").build();
    CHECK_THROWS_AS(p.connect_request(req), Error);
}

TEST("wrong scheme") {
    ClientParser p;
    auto req = ConnectRequest::Builder().uri("wsss://dev.ru/").build();
    CHECK_THROWS_AS(p.connect_request(req), Error);
}

TEST("body is not allowed") {
    ClientParser p;
    auto req = ConnectRequest::Builder().uri("ws://dev.ru/").body("hello world").build();
    CHECK_THROWS_AS(p.connect_request(req), Error);
}

TEST("to_string twice") {
    ClientParser p;
    auto req = ConnectRequest::Builder().uri("wss://crazypanda.ru").build();
    auto first = p.connect_request(req);
    p.reset();
    auto second = p.connect_request(req);
    CHECK(first == second);
}
