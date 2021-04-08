#include "../test.h"

#define TEST(name) TEST_CASE("deflate-selection: " name, "[deflate-selection]")

ConnectRequestSP creq () {
    return ConnectRequest::Builder().uri("ws://crazypanda.ru").ws_key("dGhlIHNhbXBsZSBub25jZQ==").build();
}

TEST("default config") {
    ServerParser p;
    Parser::Config cfg;
    cfg.deflate.reset();
    p.configure(cfg);
    CHECK(!p.deflate_config());
    cfg.deflate = Parser::DeflateConfig();
    cfg.deflate->client_no_context_takeover = 1;
    cfg.deflate->mem_level = 5;
    p.configure(cfg);
    CHECK(p.deflate_config());
    CHECK(p.deflate_config()->compression_level == -1); // default settings
    CHECK(p.deflate_config()->mem_level == 5); // supplied settings
}

TEST("permessage-deflate extension in request") {
    ClientParser client;
    SECTION("no deflate enabled => no extension") {
        client.no_deflate();
        auto str = client.connect_request(creq());
        CHECK_THAT(str, !Contains("permessage-deflate"));
    }

    SECTION("deflate enabled => extension is present") {
        auto str = client.connect_request(creq());
        CHECK_THAT(str, Contains("permessage-deflate"));
    }

    SECTION("deflate enabled(custom params) => extension is present") {
        Parser::Config cfg;
        cfg.deflate->client_no_context_takeover = 1;
        cfg.deflate->server_no_context_takeover = 1;
        cfg.deflate->server_max_window_bits     = 13;
        cfg.deflate->client_max_window_bits     = 14;
        client.configure(cfg);
        auto str = client.connect_request(creq());
        CHECK_THAT(str, Contains("permessage-deflate"));
        CHECK_THAT(str, Contains("client_no_context_takeover"));
        CHECK_THAT(str, Contains("server_no_context_takeover"));
        CHECK_THAT(str, Contains("server_max_window_bits=13"));
        CHECK_THAT(str, Contains("client_max_window_bits=14"));
    }
}

TEST("permessage-deflate extension in server reply") {
    ClientParser client;
    ServerParser server;

    SECTION("no deflate enabled => no extension") {
        client.no_deflate();
        auto req = server.accept(client.connect_request(creq()));
        auto res_str = server.accept_response();
        CHECK_THAT(res_str, !Contains("permessage-deflate"));
    }

    SECTION("client deflate: on, server deflate: off => extension: off") {
        server.no_deflate();
        auto req_str = client.connect_request(creq());
        auto req = server.accept(req_str);
        auto res_str = server.accept_response();
        CHECK_THAT(req_str, Contains("permessage-deflate"));
        CHECK_THAT(res_str, !Contains("permessage-deflate"));
        CHECK_FALSE(client.is_deflate_active());
        CHECK_FALSE(server.is_deflate_active());
    }

    SECTION("client deflate: on, server deflate: on => extension: on") {
        auto req_str = client.connect_request(creq());
        auto req = server.accept(req_str);
        auto res_str = server.accept_response();
        client.connect(res_str);
        CHECK_THAT(req_str, Contains("permessage-deflate"));
        CHECK_THAT(res_str, Contains("permessage-deflate"));
        CHECK(server.is_deflate_active());
        CHECK(client.is_deflate_active());
        CHECK(client.established());
    }

    SECTION("client deflate: on (empty client_max_window_bits), server deflate: on => extension: on") {
        auto req_str = client.connect_request(creq());
        regex_replace(req_str, "(client_max_window_bits)=15", "$1");
        auto req = server.accept(req_str);
        auto res_str = server.accept_response();
        client.connect(res_str);
        CHECK_THAT(req_str, Contains("permessage-deflate"));
        CHECK_THAT(res_str, Contains("permessage-deflate"));
        CHECK_THAT(res_str, Contains("client_max_window_bits=15"));
        CHECK(server.is_deflate_active());
        CHECK(client.is_deflate_active());
        CHECK(client.established());
    }

    SECTION("client deflate: on (wrong params), server deflate: on => extension: off") {
        ConnectRequestSP conn_req;

        SECTION("too small window") {
            Parser::Config cfg;
            cfg.deflate->client_max_window_bits = 3;
            client.configure(cfg);
            conn_req = creq();
        }

        SECTION("too big window") {
            Parser::Config cfg;
            cfg.deflate->client_max_window_bits = 30;
            client.configure(cfg);
            conn_req = creq();
        }

        SECTION("unknown parameter") {
            conn_req = ConnectRequest::Builder()
                .uri("ws://crazypanda.ru")
                .ws_key("dGhlIHNhbXBsZSBub25jZQ==")
                .ws_extensions({{"permessage-deflate", {{"hacker", "huyaker"}}}})
                .build();
        }

        SECTION("incorrect parameter") {
            conn_req = ConnectRequest::Builder()
                .uri("ws://crazypanda.ru")
                .ws_key("dGhlIHNhbXBsZSBub25jZQ==")
                .ws_extensions({{"permessage-deflate", {{"client_max_window_bits", "kak tebe takoe, Ilon Mask?"}}}})
                .build();
        }

        auto req_str = client.connect_request(conn_req);
        auto req = server.accept(req_str);
        auto res_str = server.accept_response();
        client.connect(res_str);
        CHECK_THAT(req_str, Contains("permessage-deflate"));
        CHECK_THAT(res_str, !Contains("permessage-deflate"));
        CHECK_FALSE(client.is_deflate_active());
        CHECK_FALSE(server.is_deflate_active());
        CHECK(client.established());
    }

    SECTION("client deflate: on, server deflate: on (wrong params) => no connection") {
        client.connect_request(creq());
        string res_str;

        SECTION("offected other windows size") {
            res_str = "HTTP/1.1 101 Switching Protocols\r\n"
                      "Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=\r\n"
                      "Sec-WebSocket-Extensions: permessage-deflate; server_max_window_bits=13; client_max_window_bits=15\r\n"
                      "Connection: Upgrade\r\n"
                      "Server: Panda-WebSocket\r\n"
                      "Upgrade: websocket\r\n"
                      "\r\n";
        }
        SECTION("offected garbage windows size") {
            res_str = "HTTP/1.1 101 Switching Protocols\r\n"
                      "Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=\r\n"
                      "Sec-WebSocket-Extensions: permessage-deflate; server_max_window_bits=zzzz; client_max_window_bits=15\r\n"
                      "Connection: Upgrade\r\n"
                      "Server: Panda-WebSocket\r\n"
                      "Upgrade: websocket\r\n"
                      "\r\n";
        }
        SECTION("offected garbage extension parameter") {
            res_str = "HTTP/1.1 101 Switching Protocols\r\n"
                      "Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=\r\n"
                      "Sec-WebSocket-Extensions: permessage-deflate; server_max_window_bits=15; client_max_window_bits=15; hello=world\r\n"
                      "Connection: Upgrade\r\n"
                      "Server: Panda-WebSocket\r\n"
                      "Upgrade: websocket\r\n"
                      "\r\n";
        }

        auto conn_res = client.connect(res_str);
        CHECK_FALSE(client.established());
        CHECK_FALSE(client.is_deflate_active());
        CHECK(conn_res->error() == ErrorCode(errc::deflate_negotiation_failed));
    }
}

TEST("configuration getters") {
    ClientParser client;

    Parser::Config cfg;
    cfg.max_frame_size     = 7;
    cfg.max_message_size   = 8;
    cfg.max_handshake_size = 9;
    cfg.deflate->client_no_context_takeover = 1;
    cfg.deflate->server_no_context_takeover = 1;
    cfg.deflate->server_max_window_bits     = 13;
    cfg.deflate->client_max_window_bits     = 14;
    cfg.deflate->mem_level                  = 3;
    cfg.deflate->compression_level          = 2;
    cfg.deflate->strategy                   = 1;
    cfg.deflate->compression_threshold      = 1000;
    client.configure(cfg);

    CHECK(client.max_frame_size() == 7);
    CHECK(client.max_message_size() == 8);
    CHECK(client.max_handshake_size() == 9);
    CHECK(client.deflate_config()->client_no_context_takeover == 1);
    CHECK(client.deflate_config()->server_no_context_takeover == 1);
    CHECK(client.deflate_config()->server_max_window_bits == 13);
    CHECK(client.deflate_config()->client_max_window_bits == 14);
    CHECK(client.deflate_config()->mem_level == 3);
    CHECK(client.deflate_config()->compression_level == 2);
    CHECK(client.deflate_config()->strategy == 1);
    CHECK(client.deflate_config()->compression_threshold == 1000);

    client.no_deflate();
    CHECK_FALSE(client.deflate_config());
}

TEST("server ignores permessage-deflate option with window_bits=8, and uses no compression") {
    Parser::Config cfg;
    cfg.deflate->client_max_window_bits = 9;

    ClientParser client(cfg);
    ServerParser server;

    auto req_str = client.connect_request(creq());

    SECTION("8-bit request is rejected") {
        regex_replace(req_str, "window_bits=9", "window_bits=8");
        auto req = server.accept(req_str);
        auto res_str = server.accept_response();
        client.connect(res_str);
        CHECK_THAT(req_str, Contains("permessage-deflate"));
        CHECK_THAT(res_str, !Contains("permessage-deflate"));
        CHECK_FALSE(server.is_deflate_active());
        CHECK_FALSE(client.is_deflate_active());
        CHECK(client.established());
    }

    SECTION("8-bit response is rejected") {
        auto req = server.accept(req_str);
        auto res_str = server.accept_response();
        CHECK_THAT(req_str, Contains("permessage-deflate"));
        CHECK_THAT(res_str, Contains("permessage-deflate"));
        CHECK(server.is_deflate_active());

        regex_replace(res_str, "window_bits=9", "window_bits=8");
        auto conn_res = client.connect(res_str);
        CHECK_FALSE(client.established());
        CHECK_FALSE(client.is_deflate_active());
        CHECK(conn_res->error() == ErrorCode(errc::deflate_negotiation_failed));
    }

    SECTION("9-bit window is OK") {
        server.configure(cfg);
        auto req = server.accept(req_str);
        auto res_str = server.accept_response();
        client.connect(res_str);
        CHECK(client.established());
        CHECK(client.is_deflate_active());
        CHECK(server.is_deflate_active());
        CHECK(client.effective_deflate_config()->client_max_window_bits == 9);
        CHECK(client.effective_deflate_config()->server_max_window_bits == 15);
        CHECK(server.effective_deflate_config()->client_max_window_bits == 9);
        CHECK(server.effective_deflate_config()->server_max_window_bits == 15);
    }
}

TEST("SRV-1229 bufix") {
    string req_str = "GET / HTTP/1.1\r\n"
                     "User-Agent: Panda-WebSocket\r\n"
                     "Upgrade: websocket\r\n"
                     "Connection: Upgrade\r\n"
                     "Host: crazypanda.ru\r\n"
                     "Sec-WebSocket-Extensions: permessage-deflate; server_max_window_bits=13; client_max_window_bits\r\n"
                     "Sec-WebSocket-Version: 13\r\n"
                     "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n"
                     "\r\n";
    ServerParser server;
    auto req = server.accept(req_str);
    auto res_str = server.accept_response();
    CHECK_THAT(res_str, Contains("permessage-deflate"));
    CHECK_THAT(res_str, Contains("client_max_window_bits=15"));
}
