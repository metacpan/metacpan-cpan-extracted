#include "../test.h"
#include <regex>

#define TEST(name) TEST_CASE("client-connect: " name, "[client-connect]")

void test_connect (ConnectRequestSP req, int code, string msg, ErrorCode error, string ws_accept_key = "", string ws_protocol = "",
                   HeaderValues ws_extensions = {}, Headers headers = {})
{
    ClientParser p;
    ServerParser sp;
    auto str  = p.connect_request(req);
    auto creq = sp.accept(str);
    REQUIRE(creq);
    auto res_str = creq->error() ? sp.accept_error() : sp.accept_response();
    ConnectResponseSP cres;

    SECTION("whole data") {
        cres = p.connect(res_str);
    }
    SECTION("chunks") {
        size_t sz = 5;
        while (res_str && !cres) {
            auto chunk = res_str.substr(0, sz);
            if (res_str.length() > sz) res_str.offset(sz);
            else res_str = "";
            cres = p.connect(chunk);
        }
        CHECK(res_str == "");
    }

    CHECK(cres->code == code);
    CHECK(cres->message == msg);
    CHECK(cres->error() == error);
    if (ws_accept_key)        CHECK(cres->ws_accept_key() == ws_accept_key);
    if (ws_protocol)          CHECK(cres->ws_protocol() == ws_protocol);
    if (ws_extensions.size()) CHECK(cres->ws_extensions() == ws_extensions);

    if (headers.size()) {
        auto hdr = cres->headers;
        hdr.remove("server");
        CHECK(hdr == headers);
    }

    if (error) CHECK_FALSE(p.established());
    else       CHECK(p.established());
}

TEST("simple connect") {
    test_connect(
        ConnectRequest::Builder()
            .uri("ws://crazypanda.ru")
            .ws_key("dGhlIHNhbXBsZSBub25jZQ==")
            .ws_protocol("killme")
            .ws_extensions({
                {"permessage-deflate", {{"client_max_window_bits", ""}}},
            })
            .build(),
        101, "Switching Protocols", {}, "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=", "killme",
        {
            {"permessage-deflate", {{"client_max_window_bits", "15"}}},
        },
        {
            {"connection",               "Upgrade"},
            {"upgrade",                  "websocket"},
            {"sec-websocket-accept",     "s3pPLMBiTxaQ9kYGzzhZRbK+xOo="},
            {"sec-websocket-protocol",   "killme"},
            {"sec-websocket-extensions", "permessage-deflate; client_max_window_bits=15"},
            {"content-length",           "0"},
        }
    );
}

TEST("wrong accept key") {
    ClientParser p;
    ServerParser sp;
    auto str = p.connect_request(ConnectRequest::Builder().uri("ws://a.ru").build());
    sp.accept(str);
    auto res_str = sp.accept_response();
    regex_replace(res_str, "(Sec-WebSocket-Accept: )", "$1 a");
    auto cres = p.connect(res_str);
    CHECK(cres->error() == ErrorCode(errc::sec_accept_missing));
}

TEST("version upgrade required") {
    test_connect(
        ConnectRequest::Builder()
            .uri("ws://a.ru")
            .ws_version(14)
            .build(),
        426, "Upgrade Required", ErrorCode(errc::unsupported_version)
    );
}

TEST("wrong code") {
    ClientParser p;
    ServerParser sp;
    auto str = p.connect_request(ConnectRequest::Builder().uri("ws://a.ru").build());
    sp.accept(str);
    auto res_str = sp.accept_response();
    regex_replace(res_str, "(HTTP/1.1) (\\d+)", "$1 102");
    auto cres = p.connect(res_str);
    CHECK(cres->error() == ErrorCode(errc::response_code_101));
}

TEST("wrong connection header") {
    ClientParser p;
    ServerParser sp;
    auto str = p.connect_request(ConnectRequest::Builder().uri("ws://a.ru").build());
    sp.accept(str);
    auto res_str = sp.accept_response();
    regex_replace(res_str, "(Connection:) (\\S+)", "$1 migrate");
    auto cres = p.connect(res_str);
    CHECK(cres->error() == ErrorCode(errc::connection_mustbe_upgrade));
}

TEST("wrong upgrade header") {
    ClientParser p;
    ServerParser sp;
    auto str = p.connect_request(ConnectRequest::Builder().uri("ws://a.ru").build());
    sp.accept(str);
    auto res_str = sp.accept_response();
    regex_replace(res_str, "(Upgrade:) (\\S+)", "$1 huysocket");
    auto cres = p.connect(res_str);
    CHECK(cres->error() == ErrorCode(errc::upgrade_mustbe_websocket));
}

TEST("frame just after handshake is reachable") {
    ClientParser p;
    ServerParser sp;
    auto str = p.connect_request(ConnectRequest::Builder().uri("ws://a.ru").build());
    sp.accept(str);
    auto res_str = sp.accept_response();
    res_str += gen_message().mask().payload("hello!!").str();
    auto cres = p.connect(res_str);
    CHECK(p.established());
    auto msg = get_message(p);
    REQUIRE(msg);
    CHECK(msg->payload[0] == "hello!!");
}
