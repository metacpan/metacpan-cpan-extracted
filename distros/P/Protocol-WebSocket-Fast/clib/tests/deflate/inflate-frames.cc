#include "../test.h"

#define TEST(name) TEST_CASE("inflate-frames: " name, "[inflate-frames]")

struct Parsers {
    ServerParser server;
    ClientParser client;

    Parsers (Parser::Config ccfg = {}, Parser::Config scfg = {}, bool do_not_override_threshold = false) {
        if (ccfg.deflate && !do_not_override_threshold) ccfg.deflate->compression_threshold = 0;
        if (scfg.deflate && !do_not_override_threshold) scfg.deflate->compression_threshold = 0;
        server.configure(scfg);
        client.configure(ccfg);

        auto con_str = client.connect_request(ConnectRequest::Builder()
            .uri("ws://crazypanda.ru")
            .ws_key("dGhlIHNhbXBsZSBub25jZQ==")
            .build()
        );

        server.accept(con_str);
        auto res_str = server.accept_response();
        client.connect(res_str);

        if (!server.established() || !client.established()) {
            throw "should not happen";
        }
    }
};

TEST("empty payload frame") {
    string payload = "";
    Parsers p;
    auto bin = p.server.start_message(DeflateFlag::YES).send(payload);
    auto f = get_frame(p.client, bin);
    CHECK(f->payload.empty());
}

TEST("tiny payload") {
    string payload = "preved";
    Parsers p;
    auto bin = p.server.start_message(DeflateFlag::YES).send(payload);
    auto f = get_frame(p.client, bin);
    CHECK(f->payload[0] == payload);
}

TEST("medium payload") {
    auto payload = repeat("0", 1923);
    Parsers p;
    auto bin = p.server.start_message(DeflateFlag::YES).send(payload);
    auto f = get_frame(p.client, bin);
    CHECK((f->payload[0] == payload));
}

TEST("medium payload (it)") {
    std::vector<string_view> payload(1923, "0");
    Parsers p;
    auto bin = p.server.start_message(DeflateFlag::YES).send(payload.begin(), payload.end());
    auto f = get_frame(p.client, bin);
    CHECK((f->payload[0] == join(payload)));
}

TEST("large payload") {
    auto payload = repeat("0", 1024 * 1024);
    Parsers p;
    auto bin = p.server.start_message(DeflateFlag::YES).send(payload);
    auto f = get_frame(p.client, bin);
    CHECK((f->payload[0] == payload));
}

TEST("1-frame-message (tiny payload)") {
    string_view payload = "hello-world";
    Parsers p;
    auto bin = p.server.start_message(DeflateFlag::YES).send(payload, IsFinal::YES);
    auto m = get_message(p.client, bin);
    CHECK(join(m->payload) == payload);
}

TEST("message, 2 frames, context_takeover = true") {
    std::vector<string_view> payload;
    SECTION("tiny payload") {
        payload = std::vector<string_view>{"a", "b"};
    }
    SECTION("medium payload") {
        payload = std::vector<string_view>(1024, "0");
    }
    Parsers p;
    auto builder = p.server.start_message(DeflateFlag::YES);
    auto bin1 = builder.send(payload.begin(), payload.end());
    auto bin2 = builder.send(payload.begin(), payload.end(), IsFinal::YES);
    auto m = get_message(p.client, bin1 + bin2);
    CHECK((join(m->payload) == repeat(join(payload),2)));
}

TEST("2 messages, 2 frames, server_context_takeover = false, medium payload") {
    std::vector<string_view> payload(1024, "0");
    Parser::Config cfg;
    cfg.deflate->server_no_context_takeover = 1;
    Parsers p(cfg);
    auto bin1 = p.server.start_message(DeflateFlag::YES).send(payload.begin(), payload.end(), IsFinal::YES);
    auto bin2 = p.server.start_message(DeflateFlag::YES).send(payload.begin(), payload.end(), IsFinal::YES);
    CHECK(bin1.length() == bin2.length()); // make sure there is no context takeover
    auto msgs = get_messages(p.client, bin1+bin2);
    CHECK(msgs.size() == 2);
    CHECK((msgs[0]->payload[0] == join(payload)));
    CHECK((msgs[1]->payload[0] == join(payload)));
}

TEST("2 messages, 2 frames, client_context_takeover = false, medium payload") {
    std::vector<string_view> payload(1024, "0");
    Parser::Config cfg;
    cfg.deflate->client_no_context_takeover = 1;
    Parsers p(cfg);
    auto bin1 = p.client.start_message(DeflateFlag::YES).send(payload.begin(), payload.end(), IsFinal::YES);
    auto bin2 = p.client.start_message(DeflateFlag::YES).send(payload.begin(), payload.end(), IsFinal::YES);
    CHECK(bin1.length() == bin2.length()); // make sure there is no context takeover
    auto msgs = get_messages(p.server, bin1+bin2);
    CHECK(msgs.size() == 2);
    CHECK((msgs[0]->payload[0] == join(payload)));
    CHECK((msgs[1]->payload[0] == join(payload)));
}

TEST("2 messages, 2 frames, server_context_takeover = false = client_context_takeover = false, medium payload, custom windows") {
    std::vector<string_view> payload(1024*10, "0");
    Parser::Config cfg;
    cfg.deflate->client_no_context_takeover = 1;
    cfg.deflate->server_no_context_takeover = 1;
    cfg.deflate->client_max_window_bits = 10;
    cfg.deflate->server_max_window_bits = 11;
    cfg.deflate->compression_level = 1;
    Parsers p(cfg);
    auto bin1 = p.client.start_message(DeflateFlag::YES).send(payload.begin(), payload.end(), IsFinal::YES);
    auto bin2 = p.client.start_message(DeflateFlag::YES).send(payload.begin(), payload.end(), IsFinal::YES);
    CHECK(bin1.length() == bin2.length()); // make sure there is no context takeover
    auto msgs = get_messages(p.server, bin1+bin2);
    CHECK(msgs.size() == 2);
    CHECK((msgs[0]->payload[0] == join(payload)));
    CHECK((msgs[1]->payload[0] == join(payload)));
}

TEST("multiframe message") {
    std::vector<std::array<string_view,1>> payloads = {{"first"}, {"second"}, {"third"}};
    Parsers p;
    auto bin = p.client.message().deflate(true).send_multiframe(payloads.begin(), payloads.end());
    auto m = get_message(p.server, join(bin));
    CHECK(join(m->payload) == "firstsecondthird");
}

TEST("multiframe message (with empty pieces)") {
    std::vector<std::array<string_view,1>> payloads = {{""}, {"hello"}, {""}};
    Parsers p;
    auto bin = p.client.message().deflate(true).send_multiframe(payloads.begin(), payloads.end());
    auto m = get_message(p.server, join(bin));
    CHECK(join(m->payload) == "hello");
}

TEST("multiframe message (empty)") {
    std::vector<std::array<string_view,1>> payloads = {{""}, {""}, {""}};
    Parsers p;
    auto bin = p.client.message().deflate(true).send_multiframe(payloads.begin(), payloads.end());
    auto m = get_message(p.server, join(bin));
    CHECK_FALSE(m->payload_length());
}

TEST("corrupted frame") {
    auto payload = repeat("0", 1923);
    Parsers p;
    auto bin = p.server.start_message(DeflateFlag::YES).send(payload);
    auto deflate_payload = bin.substr(2);
    auto forged_bin      = bin.substr(0, 2) + "xx" + deflate_payload.substr(2);
    auto f = get_frame(p.client, forged_bin);
    CHECK(f->error() == ErrorCode(errc::inflate_error));
}

// this function generates a string with compression ratio == DeflateExt::UNCOMPRESS_PREALLOCATE_RATIO
// it reproduces scenario when inflate output buffer ends exactly on last byte of input
string generate_meiacore_1738() {
    string s = "0";
    while (1) {
        Parsers ps;
        auto bin = ps.server.start_message(DeflateFlag::YES).send(s, IsFinal::YES);
        size_t length = DeflateExt::UNCOMPRESS_PREALLOCATE_RATIO * (bin.length() - 2);
        if (length == s.length()) {
            WARN(s);
            return s;
        }
        if (length > s.length()) {
            s += "1";
        } else {
            s += rand();
        }
    }
}

TEST("MEIACORE-1738") {
    // this string was generated by generate_meiacore_1738()
    string payload = "011111111111111111111111111111111111111111111111111111111111";
    Parsers p;
    auto bin = p.server.start_message(DeflateFlag::YES).send(payload, IsFinal::YES);
    auto f = get_frame(p.client, bin);
    CHECK_FALSE(f->error());
}

TEST("corrupted 2nd frame from 3") {
    std::vector<string_view> payload(1923, "0");
    Parsers p;
    auto builder = p.server.start_message(DeflateFlag::YES);
    auto bin1    = builder.send(payload.begin(), payload.end());
    auto bin2    = builder.send(payload.begin(), payload.end());
    auto bin3    = builder.send(payload.begin(), payload.end(), IsFinal::YES);

    auto bin2_payload = bin2.substr(2);
    auto bin2_forged  = bin2.substr(0, 2) + bin2_payload.substr(0, 2) + "xx" + bin2_payload.substr(4);
    auto m = get_message(p.client, bin1 + bin2_forged + bin3);
    CHECK(m->error() == ErrorCode(errc::inflate_error));
}

TEST("compression threshold") {
    Parser::Config cfg;
    cfg.deflate->compression_threshold = 5;
    Parsers p({}, cfg, true);
    string payload1 = "1234";
    auto bin1 = p.server.message().opcode(Opcode::TEXT).send(payload1);
    CHECK(bin1.substr(2) == payload1);

    string payload2 = "12345";
    auto bin2 = p.server.message().opcode(Opcode::BINARY).send(payload2);
    CHECK(bin2.substr(2) == payload2); // binary payload isn"t compressed by default

    auto bin3 = p.server.message().opcode(Opcode::TEXT).send(payload2);
    CHECK(bin3.substr(2) != payload2); // text payload is compressed by default
}

TEST("no_deflate") {
    Parser::Config cfg;
    cfg.deflate.reset();
    Parsers p({}, cfg);
    string_view payload = "1234";
    auto bin = p.server.message().send(payload);
    CHECK(bin.substr(2) == payload);
}

TEST("zip-bomb prevention (check max_message_size)") {
    Parser::Config cfg;
    cfg.max_message_size = 100;
    cfg.deflate->compression_threshold = 0;
    Parsers p(cfg, cfg);

    SECTION("single frame/message exceeds limit") {
        auto payload = repeat("0", 101);
        auto bin = p.server.message().opcode(Opcode::TEXT).send(payload);
        auto m = get_message(p.client, bin);
        CHECK(m->error() == ErrorCode(errc::max_message_size));
    }

    SECTION("multi-frame/message exceeds limit") {
        auto payload1 = repeat("0", 60);
        auto payload2 = payload1;
        auto builder = p.server.start_message(DeflateFlag::YES);
        auto bin1 = builder.send(payload1);
        auto bin2 = builder.send(payload2, IsFinal::YES);
        auto m = get_message(p.client, bin1 + bin2);
        CHECK(m->error() == ErrorCode(errc::max_message_size));
    }

    SECTION("exact message size is allowed") {
        auto payload = repeat("0", 100);
        auto bin = p.server.message().opcode(Opcode::TEXT).send(payload);
        auto m = get_message(p.client, bin);
        CHECK_FALSE(m->error());
        CHECK_MESSAGE(m).payload(payload);
    }
}

TEST("windowBits == 8 zlib tests") {
    // https://github.com/faye/permessage-deflate-node/wiki/Denial-of-service-caused-by-invalid-windowBits-parameter-passed-to-zlib.createDeflateRaw()
    // https://github.com/madler/zlib/commit/049578f0a1849f502834167e233f4c1d52ddcbcc

    SECTION("8-bit config") {
        Parser::Config cfg;
        cfg.deflate->compression_threshold  = 0;
        cfg.deflate->server_max_window_bits = 8;
        cfg.deflate->client_max_window_bits = 8;
        Parsers p(cfg, cfg);
        CHECK_FALSE(p.server.is_deflate_active());
        CHECK_FALSE(p.client.is_deflate_active());
    }

    SECTION("9-bit config is allowed") {
        Parser::Config cfg;
        cfg.deflate->compression_threshold  = 0;
        cfg.deflate->server_max_window_bits = 9;
        cfg.deflate->client_max_window_bits = 9;
        Parsers p(cfg, cfg);
        CHECK(p.server.is_deflate_active());
        CHECK(p.client.is_deflate_active());
    }
}
