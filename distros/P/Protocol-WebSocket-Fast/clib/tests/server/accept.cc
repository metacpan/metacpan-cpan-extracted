#include  "../test.h"

#define TEST(name) TEST_CASE("server-accept: " name, "[server-accept]")

void check_req (ConnectRequestSP req) {
    CHECK(req);
    CHECK(req->headers == Headers{
        {"pragma", "no-cache"},
        {"sec-websocket-protocol", "chat"},
        {"upgrade", "websocket"},
        {"accept-encoding", "gzip, deflate, sdch"},
        {"origin", "http://www.websocket.org"},
        {"cache-control", "no-cache"},
        {"connection", "Upgrade"},
        {"cookie", "_ga=GA1.2.1700804447.1456741171"},
        {"sec-websocket-key", "dGhlIHNhbXBsZSBub25jZQ=="},
        {"host", "dev.crazypanda.ru:4680"},
        {"sec-websocket-version", "13"},
        {"user-agent", "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36"},
        {"accept-language", "ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4"},
        {"sec-websocket-extensions", "permessage-deflate; client_max_window_bits=15; server_max_window_bits=15"},
    });
    CHECK(req->uri->to_string() == "/?encoding=text");
    CHECK(req->ws_key() == "dGhlIHNhbXBsZSBub25jZQ==");
    CHECK(req->ws_protocol() == "chat");
    CHECK(req->ws_version() == 13);
}

TEST("parser create") {
    ServerParser p;
    CHECK(!p.accept_parsed());
    CHECK(!p.accepted());
    CHECK(!p.established());
}

TEST("case sensetive values") {
    ServerParser p;
    auto data = accept_packet_s();
    regex_replace(data, "Upgrade: websocket\r\n", "upgrade: websocket\r\n");
    regex_replace(data, "Connection: Upgrade\r\n", "connection: upgrade\r\n");
    auto creq = p.accept(data);
    CHECK(creq);
    CHECK(p.accepted());
}

TEST("accept chunks") {
    ServerParser p;
    auto vdata = accept_packet();
    auto last = vdata.back();
    vdata.pop_back();
    for (auto& line : vdata) {
        CHECK(!p.accept(line)); //no full data
    }
    auto creq = p.accept(last);
    check_req(creq);
    CHECK(p.accepted());
    CHECK(!p.established());
}

TEST("reset") {
    ServerParser p;
    p.accept(accept_packet_s());
    CHECK(p.accepted());

    p.reset();
    CHECK(!p.accept_parsed());
    CHECK(!p.accepted());
}

TEST("accept all") {
    ServerParser p;
    auto creq = p.accept(accept_packet_s());
    check_req(creq);
    CHECK(p.accepted());
}

TEST("accept with body") {
    ServerParser p;
    auto vdata = accept_packet();
    vdata.insert(vdata.begin() + 1, "Content-Length: 1\r\n");
    vdata.push_back("1");
    ConnectRequestSP creq;
    for (auto& chunk : vdata) {
        creq = p.accept(chunk);
        if (creq && creq->error()) break;
    }
    CHECK(creq);
    CHECK(creq->error()); // body disallowed
    CHECK(!p.accepted());
}

TEST("max_handshake_size") {
    ServerParser p;
    auto vdata = accept_packet();
    auto last = vdata.back();
    vdata.pop_back();
    auto big  = repeat("header: value\r\n", 100);
    for (auto& chunk : vdata) p.accept(chunk);
    p.accept(big);
    auto creq = p.accept(last);
    CHECK(creq); // default unlimited buffer
    CHECK(!creq->error());
    CHECK(creq->headers.get("header") == "value");

    p.reset();

    Parser::Config cfg;
    cfg.max_handshake_size = 1000;
    p.configure(cfg);

    for (auto& chunk : vdata) p.accept(chunk);
    creq = p.accept(big);
    CHECK(creq);
    CHECK(creq->error() == ErrorCode(protocol::http::errc::headers_too_large)); // buffer limit exceeded
}
