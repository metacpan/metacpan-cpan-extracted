#include "../test.h"
#include <panda/encode/base64.h>

#define TEST(name) TEST_CASE("deflate-frames: " name, "[deflate-frames]")

string default_handshake () {
    return "GET /?encoding=text HTTP/1.1\r\n"
           "Host: dev.crazypanda.ru:4680\r\n"
           "Connection: Upgrade\r\n"
           "Pragma: no-cache\r\n"
           "Cache-Control: no-cache\r\n"
           "Upgrade: websocket\r\n"
           "Origin: http://www.websocket.org\r\n"
           "Sec-WebSocket-Version: 13\r\n"
           "User-Agent: Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36\r\n"
           "Accept-Encoding: gzip, deflate, sdch\r\n"
           "Accept-Language: ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4\r\n"
           "Cookie: _ga=GA1.2.1700804447.1456741171\r\n"
           "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n"
           "Sec-WebSocket-Extensions: permessage-deflate\r\n"
           "\r\n";
}

struct MyParser : ServerParser {
    MyParser (string msg = default_handshake()) {
        accept(msg);
        accept_response();
        if (!established()) throw "should not happen";
    }
};

TEST("empty payload frame") {
    auto bin = MyParser().start_message(DeflateFlag::YES).send("", IsFinal::YES);
    CHECK_BINFRAME(bin).final().rsv1().opcode(Opcode::BINARY).payload(bin.substr(2)).binlen(2+1); // 2 header + 1 bytes empty zlib frame
}

TEST("small server2client frame (rfc7692 'Hello' sample)") {
    std::vector<string_view> payload = {"H", "e", "l", "l", "o"}; // must be <= 125
    string bin;

    SECTION("single mode") {
        bin = MyParser().start_message(Opcode::TEXT, DeflateFlag::YES).send(join(payload), IsFinal::YES);
    }
    SECTION("it mode") {
        bin = MyParser().start_message(Opcode::TEXT, DeflateFlag::YES).send(payload.begin(), payload.end(), IsFinal::YES);
    }

    auto deflate_payload = bin.substr(2);
    CHECK(encode::encode_base64(deflate_payload) == "8kjNyckHAA");
    CHECK_BINFRAME(bin).final().rsv1().opcode(Opcode::TEXT).payload(deflate_payload).binlen(9);
}

TEST("big (1923 b) server2client frame") {
    std::vector<string_view> payload(1923, "0");
    string bin;

    SECTION("single mode") {
        bin = MyParser().start_message(DeflateFlag::YES).send(join(payload), IsFinal::YES);
    }
    SECTION("it mode") {
        bin = MyParser().start_message(DeflateFlag::YES).send(payload.begin(), payload.end(), IsFinal::YES);
    }

    auto deflate_payload = bin.substr(2);
    CHECK(encode::encode_base64(deflate_payload) == "MjAYBaNgFIyCUTAKRsEAAAAA");
    CHECK_BINFRAME(bin).final().rsv1().opcode(Opcode::BINARY).payload(deflate_payload).binlen(20);
}

TEST("big (108 kb) server2client frame") {
    std::vector<string_view> payload(1024 * 108, "0");
    string bin;

    SECTION("single mode") {
        bin = MyParser().start_message(DeflateFlag::YES).send(join(payload), IsFinal::YES);
    }
    SECTION("it mode") {
        bin = MyParser().start_message(DeflateFlag::YES).send(payload.begin(), payload.end(), IsFinal::YES);
    }

    auto deflate_payload = bin.substr(4);
    CHECK_BINFRAME(bin).final().rsv1().opcode(Opcode::BINARY).payload(deflate_payload).binlen(130);
}

TEST("big (1 mb) server2client frame") {
    std::vector<string_view> payload(1024 * 1024, "0");
    string bin;

    SECTION("single mode") {
        bin = MyParser().start_message(DeflateFlag::YES).send(join(payload), IsFinal::YES);
    }
    SECTION("it mode") {
        bin = MyParser().start_message(DeflateFlag::YES).send(payload.begin(), payload.end(), IsFinal::YES);
    }

    auto deflate_payload = bin.substr(4);
    CHECK_BINFRAME(bin).final().rsv1().opcode(Opcode::BINARY).payload(deflate_payload).binlen(1038);
}

TEST("2 messages in a sequence (different due to context takeover)") {
    std::vector<string_view> payload(100, "0123456789");

    SECTION("as single lines") {
        MyParser p;
        auto bin1 = p.start_message(DeflateFlag::YES).send(join(payload), IsFinal::YES);
        auto bin2 = p.start_message(DeflateFlag::YES).send(join(payload), IsFinal::YES);
        CHECK(bin1.length() > bin2.length());
    }

    SECTION("as iterators") {
        MyParser p;
        auto bin1 = p.start_message(DeflateFlag::YES).send(payload.begin(), payload.end(), IsFinal::YES);
        auto bin2 = p.start_message(DeflateFlag::YES).send(payload.begin(), payload.end(), IsFinal::YES);
        CHECK(bin1.length() > bin2.length());
    }
}

TEST("no context takeover") {
    string handshake = "GET /?encoding=text HTTP/1.1\r\n"
                       "Host: dev.crazypanda.ru:4680\r\n"
                       "Connection: Upgrade\r\n"
                       "Upgrade: websocket\r\n"
                       "Sec-WebSocket-Version: 13\r\n"
                       "User-Agent: Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36\r\n"
                       "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n"
                       "Sec-WebSocket-Extensions: permessage-deflate; client_no_context_takeover; server_no_context_takeover\r\n"
                       "\r\n";

    MyParser p(handshake);
    auto payload = repeat("0123456789", 100);
    auto bin1 = p.start_message(DeflateFlag::YES).send(payload, IsFinal::YES);
    auto bin2 = p.start_message(DeflateFlag::YES).send(payload, IsFinal::YES);
    CHECK((bin1 == bin2));
}
