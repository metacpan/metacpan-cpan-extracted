#include  "../test.h"

#define TEST(name) TEST_CASE("server-accept_response: " name, "[server-accept_response]")

TEST("successful response") {
    ServerParser p;
    auto data = accept_packet_s();
    p.accept(data);
    CHECK(p.accepted());
    auto ans = p.accept_response();
    CHECK_THAT(ans, Contains("HTTP/1.1 101 Switching Protocols\r\n"));
    CHECK_THAT(ans, Contains("Upgrade: websocket\r\n"));
    CHECK_THAT(ans, Contains("Connection: Upgrade\r\n"));
    CHECK_THAT(ans, Contains("Sec-WebSocket-Protocol: chat\r\n"));
    CHECK_THAT(ans, Contains("Sec-WebSocket-Extensions: permessage-deflate;"));
    CHECK_THAT(ans, Contains("Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=\r\n"));
    CHECK(p.established());
}

TEST("successful response with args") {
    ServerParser p;
    auto data = accept_packet_s();
    p.accept(data);
    CHECK(p.accepted());

    ConnectResponseSP cres = new ConnectResponse();
    cres->ws_protocol("jopa");
    cres->ws_extensions({{"ext1", {}}, {"ext2", {{"arg1", "1"}}}, {"ext3", {}}});
    cres->headers = Headers{{"h1", "1"}};
    auto ans = p.accept_response(cres);
    CHECK_THAT(ans, Contains("HTTP/1.1 101 Switching Protocols\r\n"));
    CHECK_THAT(ans, Contains("Sec-WebSocket-Protocol: jopa\r\n"));
    CHECK_THAT(ans, Contains("h1: 1\r\n"));
    CHECK_THAT(ans, !Contains("Sec-WebSocket-Extensions")); // unsupported extensions removed
}
