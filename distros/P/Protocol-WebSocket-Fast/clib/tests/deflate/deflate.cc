#include "../test.h"
#include <vector>
#include <panda/encode/base16.h>
#include <panda/encode/base64.h>

using namespace panda;
using namespace panda::protocol::websocket;

#define TEST(name) TEST_CASE("deflate: " name, "[deflate]")

struct Parsers {
    ServerParser server;
    ClientParser client;

    Parsers (Parser::Config cfg = {}) {
        cfg.deflate->compression_threshold = 0;
        server.configure(cfg);
        client.configure(cfg);

        auto con_str = client.connect_request(ConnectRequest::Builder()
            .uri("ws://crazypanda.ru")
            .ws_key("dGhlIHNhbXBsZSBub25jZQ==")
            .ws_version(13)
            .ws_protocol("ws")
            .build()
        );

        server.accept(con_str);
        auto res_str = server.accept_response();
        client.connect(res_str);

        if (!server.established() || !client.established() || !server.is_deflate_active() || !client.is_deflate_active()) {
            throw "should not happen";
        }
    }
};

TEST("FrameSender::send (iterator)") {
    Parsers p;
    std::vector<string> fragments;
    fragments.push_back("hello");
    fragments.push_back(" world");
    auto data = p.server.start_message(DeflateFlag::YES).send(fragments.begin(), fragments.end(), IsFinal::YES);
    auto messages_it = p.client.get_messages(data);
    REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
    REQUIRE(messages_it.begin()->payload[0] == "hello world");
}

TEST("FrameSender::send (iterator, empty)") {
    Parsers p;
    std::vector<string> fragments;
    auto data = p.server.start_message(DeflateFlag::YES).send(fragments.begin(), fragments.end(), IsFinal::YES);
    auto messages_it = p.client.get_messages(data);
    REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
    REQUIRE(messages_it.begin()->payload.empty());
}

TEST("FrameSender::send (iterator with holes)") {
    Parsers p;
    std::vector<string> fragments;
    fragments.push_back("");
    fragments.push_back("hello");
    fragments.push_back("");
    fragments.push_back(" world");
    fragments.push_back("");
    auto data = p.server.start_message(DeflateFlag::YES).send(fragments.begin(), fragments.end(), IsFinal::YES);
    auto messages_it = p.client.get_messages(data);
    REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
    auto it = messages_it.begin();
    REQUIRE(it->payload.size() == 1);
    REQUIRE(it->payload[0] == "hello world");
}

TEST("MessageBuilder::send (fragmented message iterator)") {
    Parsers p;
    std::vector<string> fragments;
    fragments.push_back("hello");
    fragments.push_back(" world");
    auto data = p.server.message().deflate(true).send(fragments.begin(), fragments.end());
    auto messages_it = p.client.get_messages(data);
    REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
    REQUIRE(messages_it.begin()->payload[0] == "hello world");
}

TEST("MessageBuilder::send (fragmented message iterator, hole in the middle)") {
    Parsers p;
    std::vector<string> fragments;
    fragments.push_back("hello");
    fragments.push_back("");
    fragments.push_back("");
    fragments.push_back(" world");
    auto data = p.server.message().deflate(true).send(fragments.begin(), fragments.end());
    auto messages_it = p.client.get_messages(data);
    REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
    REQUIRE(messages_it.begin()->payload[0] == "hello world");
}

TEST("MessageBuilder::send (empty string)") {
    Parsers p;
    panda::string item = "";
    auto data = p.server.message().deflate(true).send(item);
    auto messages_it = p.client.get_messages(data);
    REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
    REQUIRE(messages_it.begin()->payload.size() == 0);
}

TEST("MessageBuilder::send (fragmented message iterator, empty)") {
    Parsers p;
    std::vector<string> fragments;
    fragments.push_back("");
    auto data = p.server.message().deflate(true).send(fragments.begin(), fragments.end());
    auto messages_it = p.client.get_messages(data);
    REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
    REQUIRE(messages_it.begin()->payload.size() == 0);
}

TEST("MessageBuilder::send_multiframe (fragmented multi-frame iterator, 1 fragment)") {
    Parsers p;
    std::vector<std::vector<string>> pieces;

    std::vector<string> fragments1;
    fragments1.push_back("hello");
    fragments1.push_back(" world!");
    pieces.push_back(fragments1);


    auto builder = p.server.message();
    auto data = join(builder.deflate(true).send_multiframe(pieces.begin(), pieces.end()));
    auto messages_it = p.client.get_messages(data);
    REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);

    auto it = messages_it.begin();
    REQUIRE(it->payload[0] == "hello world!");
}

TEST("MessageBuilder::send_multiframe (fragmented multi-frame iterator, 2 fragments)") {
    Parsers p;
    std::vector<std::vector<string>> pieces;

    std::vector<string> fragments1;
    fragments1.push_back("hello");
    fragments1.push_back(" world!");
    pieces.push_back(fragments1);

    std::vector<string> fragments2;
    fragments2.push_back(" Let's do ");
    fragments2.push_back("some testing");
    pieces.push_back(fragments2);

    auto builder = p.server.message();
    auto data = join(builder.deflate(true).send_multiframe(pieces.begin(), pieces.end()));
    REQUIRE(data.find("hello") == std::string::npos);
    auto messages_it = p.client.get_messages(data);
    REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);

    auto it = messages_it.begin();
    REQUIRE(it->payload.size() == 2);
    REQUIRE(it->payload[0] == "hello world!");
    REQUIRE(it->payload[1] == " Let's do some testing");
}

TEST("MessageBuilder::send_multiframe (fragmented multi-frame iterator, 2 fragments, last empty)") {
    Parsers p;
    std::vector<std::vector<string>> pieces;

    std::vector<string> fragments1;
    fragments1.push_back("hello");
    fragments1.push_back(" world!");
    pieces.push_back(fragments1);

    std::vector<string> fragments2;
    pieces.push_back(fragments2);

    auto builder = p.server.message();
    auto data = join(builder.deflate(true).send_multiframe(pieces.begin(), pieces.end()));
    REQUIRE(data.find("hello") == std::string::npos);
    auto messages_it = p.client.get_messages(data);
    REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);

    auto it = messages_it.begin();
    REQUIRE(it->payload.size() == 1);
    REQUIRE(it->payload[0] == "hello world!");
}

TEST("MessageBuilder::send_multiframe (fragmented multi-frame iterator, 4 fragments, empty middle)") {
    Parsers p;
    std::vector<std::vector<string>> pieces;

    std::vector<string> fragments1;
    fragments1.push_back("hello");
    fragments1.push_back(" world");
    pieces.push_back(fragments1);

    std::vector<string> fragments2;
    pieces.push_back(fragments2);

    std::vector<string> fragments3;
    fragments3.push_back("");
    pieces.push_back(fragments3);

    std::vector<string> fragments4;
    fragments4.push_back("!");
    pieces.push_back(fragments4);

    auto builder = p.server.message();
    auto data = join(builder.deflate(true).send_multiframe(pieces.begin(), pieces.end()));
    REQUIRE(data.find("hello") == std::string::npos);
    auto messages_it = p.client.get_messages(data);
    REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);

    auto it = messages_it.begin();
    REQUIRE(it->payload.size() == 2);
    REQUIRE(it->payload[0] == "hello world");
    REQUIRE(it->payload[1] == "!");
}

TEST("MessageBuilder::send_multiframe (fragmented multi-frame iterator, 2 fragments, both empty)") {
    Parsers p;
    std::vector<std::vector<string>> pieces;

    std::vector<string> fragments1;
    pieces.push_back(fragments1);

    std::vector<string> fragments2;
    pieces.push_back(fragments2);

    auto builder = p.server.message();
    auto data = join(builder.deflate(true).send_multiframe(pieces.begin(), pieces.end()));
    REQUIRE(data.find("hello") == std::string::npos);
    auto messages_it = p.client.get_messages(data);
    REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);

    auto it = messages_it.begin();
    REQUIRE(it->payload.empty());
}

TEST("empty compressed frame with zero payload") {
    Parsers p;
    string payload;
    auto data = p.server.start_message(DeflateFlag::YES).send(payload, IsFinal::YES);
    REQUIRE(data.capacity() >= data.length());
    REQUIRE(data.length() == 3);

    SECTION("zero uncompressed payload") {
        auto messages_it = p.client.get_messages(data);
        REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
        REQUIRE(messages_it.begin()->payload_length() == 0);
    }

    SECTION("non-zero network payload") {
        auto frames_it = p.client.get_frames(data);
        REQUIRE(std::distance(frames_it.begin(), frames_it.end()) == 1);
        REQUIRE(frames_it.begin()->payload_length() == 1);
    }
}

TEST("compressed frame with zero payload") {
    Parsers p;
    string payload;
    REQUIRE(payload.length() == 0);
    FrameHeader fh(Opcode::TEXT, true, true, false, false, true, (uint32_t)std::rand());
    auto data_string = Frame::compile(fh, payload);
    auto messages_it = p.client.get_messages(data_string);
    REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
    REQUIRE(messages_it.begin()->payload_length() == 0);
}

TEST("Control compressed frame") {
    Parsers p;
    string payload;
    FrameHeader fh(Opcode::PING, true, true, false, false, true, (uint32_t)std::rand());
    auto data_string = Frame::compile(fh, payload);
    auto frames_it = p.client.get_frames(data_string);
    REQUIRE(frames_it.begin()->error() & errc::control_frame_compression);
}

TEST("send compressed frame bigger then original") {
    Parsers p;
    string payload = encode::decode_base16("8e008f8f8f0090909000919191009292");

    auto data = p.server.start_message(DeflateFlag::YES).send(payload, IsFinal::YES);
    REQUIRE(data.length() >= 2 + 19);
    auto messages_it = p.client.get_messages(data);
    REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
    REQUIRE_FALSE(messages_it.begin()->error());
    REQUIRE(messages_it.begin()->payload[0] == payload);
}

TEST("zlib test") {
    string payload = encode::decode_base16("8e008f8f8f0090909000919191009292");
    char buff1[50];
    char buff2[50];
    char buff1_out[50];
    char buff2_out[50];

    memset(buff1, 0, 50);
    memset(buff2, 0, 50);
    memset(buff1_out, 0, 50);
    memset(buff2_out, 0, 50);

    z_stream tx_stream1;
    tx_stream1.avail_in = 0;
    tx_stream1.zalloc = Z_NULL;
    tx_stream1.zfree = Z_NULL;
    tx_stream1.opaque = Z_NULL;
    auto r = deflateInit2(&tx_stream1, -1, Z_DEFLATED, -1 * 15, 8, Z_DEFAULT_STRATEGY);
    REQUIRE(r == Z_OK);

    tx_stream1.next_in = reinterpret_cast<Bytef*>(payload.buf());
    tx_stream1.avail_in = static_cast<uInt>(payload.length());
    tx_stream1.avail_out = 50;
    tx_stream1.next_out = reinterpret_cast<Bytef*>(buff1);
    r = deflate(&tx_stream1, Z_SYNC_FLUSH);
    REQUIRE(r == Z_OK);
    REQUIRE(tx_stream1.total_out == 23);


    z_stream tx_stream2;
    tx_stream2.avail_in = 0;
    tx_stream2.zalloc = Z_NULL;
    tx_stream2.zfree = Z_NULL;
    tx_stream2.opaque = Z_NULL;
    r = deflateInit2(&tx_stream2, -1, Z_DEFLATED, -1 * 15, 8, Z_DEFAULT_STRATEGY);
    REQUIRE(r == Z_OK);
    REQUIRE(tx_stream1.avail_out !=0);

    tx_stream2.next_in = reinterpret_cast<Bytef*>(payload.buf());
    tx_stream2.avail_in = static_cast<uInt>(payload.length());
    tx_stream2.avail_out = 23;
    tx_stream2.next_out = reinterpret_cast<Bytef*>(buff2);
    r = deflate(&tx_stream2, Z_SYNC_FLUSH);
    REQUIRE(r == Z_OK);
    REQUIRE(tx_stream2.total_out == 23);
    REQUIRE(tx_stream2.avail_out == 0);  // !!! ???

    tx_stream2.avail_out = 50 - 23;
    r = deflate(&tx_stream2, Z_SYNC_FLUSH);
    REQUIRE(r == Z_OK);
    //REQUIRE(tx_stream2.total_out == tx_stream1.total_out); /// !!! ???

    z_stream rx_stream1;
    rx_stream1.avail_in = 0;
    rx_stream1.next_in = Z_NULL;
    rx_stream1.zalloc = Z_NULL;
    rx_stream1.zfree = Z_NULL;
    rx_stream1.opaque = Z_NULL;

    r = inflateInit2(&rx_stream1, -1 * 15);
    REQUIRE(r == Z_OK);

    rx_stream1.next_in = reinterpret_cast<Bytef*>(buff1);
    rx_stream1.avail_in = static_cast<uInt>(tx_stream1.avail_out);
    rx_stream1.next_out = reinterpret_cast<Bytef*>(buff1_out);
    rx_stream1.avail_out = 50;
    r = inflate(&rx_stream1, Z_SYNC_FLUSH);
    REQUIRE(r == Z_OK);

    z_stream rx_stream2;
    rx_stream2.avail_in = 0;
    rx_stream2.zalloc = Z_NULL;
    rx_stream2.zfree = Z_NULL;
    rx_stream2.opaque = Z_NULL;

    r = inflateInit2(&rx_stream2, -1 * 15);
    REQUIRE(r == Z_OK);

    rx_stream2.next_in = reinterpret_cast<Bytef*>(buff2);
    rx_stream2.avail_in = static_cast<uInt>(tx_stream2.avail_out);
    rx_stream2.next_out = reinterpret_cast<Bytef*>(buff2_out);
    rx_stream2.avail_out = 50;
    r = inflate(&rx_stream2, Z_SYNC_FLUSH);
    REQUIRE(r == Z_OK);

    deflateEnd(&tx_stream1);
    deflateEnd(&tx_stream2);
    inflateEnd(&rx_stream1);
    inflateEnd(&rx_stream2);
}

TEST("SRV-1236") {
    Parser::Config cfg;
    cfg.deflate->client_no_context_takeover = true;
    Parsers p(cfg);

    SECTION("buggy sample (does work)") {
        string data_sample = "UlBQUDLWM1eyUqjmUoABpaTUjMSyzPwioLCSv7eSDhYp55z84lQs8imlRYklmfl5QCkjZPGi1Nz8klSwLuf8FJBOQwMDNBUF+UUlaZk5YGMTS0vykxIz8goqSzLy8+IN4s2AODmxODXeON5cL6sYaANUby3MECUTPUM9Q9K8AgAAAP//";
        string payload = encode::decode_base64(data_sample);
        FrameHeader fh(Opcode::TEXT, true, true, false, false, true, (uint32_t)std::rand());
        auto data = Frame::compile(fh, payload);
        auto messages_it = p.server.get_messages(data);
        REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
        REQUIRE(!messages_it.begin()->error());
    }

    SECTION("12.1.3 :: false inflate error caused by incorrectly handling Z_BUF_ERROR") {
        string data_samples[] = {
            "0uFSgAGlpNSMxLLM/CLnnPziVCUrBSV/byUdJPmU0qLEksz8PKCUCbJ4UWpufkkqWJdzfgpIp6GBgRGqioL8opK0zBywsYmlJflJiRl5BZUlGfl58QbxZkCcnFicGm8cb6yXVQy0Aaq3FmaIkrGeCVBrNRbXYnEoCR4BAAAA//8",
            "MjTX4VKAAaWi1Nz8klTnnPziVOf8lFQlKwVDAwMjVBUF+UUlaZk5IEmlxNKS/KTEjLyCypKM/Lx4g3gzIE5OLE6NN4430csqzs9TguqthRmiZKxnCtRajWRmUmpGYllmfhHIRH9vJR0sUmAnYZFPKS1KLMkEWmOlYESWRwAAAAD//w",
            "ysxJVbJSUEosLclPSszIK6gsycjPizeINwPi5MTi1HjjeFO9rOL8PCUuBTCo1YEylIz1zIBaq6FckEhSakZiWWZ+EchEf28lHSxSzjn5xalY5FNKixJLMoHWWCkYIYsXpebml6SCdTnnp4B0GhoYoKkoyC8qScsk7BEzLB4BAAAA//8",
            "UlBQUDLWM1eyUqjmUoABpaTUjMSyzPwioLCSv7eSDhYp55z84lQs8imlRYklmfl5QCkjZPGi1Nz8klSwLuf8FJBOQwMDNBUF+UUlaZk5YGMTS0vykxIz8goqSzLy8+IN4s2AODmxODXeON5cL6sYaANUby3MECUTPUM9Q9K8AgAAAP//",
        };
        for(auto it = std::begin(data_samples); it != std::end(data_samples); ++it){
            string payload = encode::decode_base64(*it);
            FrameHeader fh(Opcode::TEXT, true, true, false, false, true, (uint32_t)std::rand());
            auto data = Frame::compile(fh, payload);
            auto messages_it = p.server.get_messages(data);
            REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
            REQUIRE_FALSE(messages_it.begin()->error());
        }
    }

    SECTION("12.1.11 (no rsv1 flag on 2nd frame == that's correct)") {
        string payload1 = encode::decode_base64("MjAgFQAAAAD//w");
        string payload2 = encode::decode_base64("Ih0AAAAA//8");

        FrameHeader fh1(Opcode::TEXT, false, true, false, false, true, (uint32_t)std::rand());
        auto data1 = Frame::compile(fh1, payload1);

        FrameHeader fh2(Opcode::CONTINUE, true, false, false, false, true, (uint32_t)std::rand());
        auto data2 = Frame::compile(fh2, payload2);
        auto data = data1 + data2;

        auto messages_it = p.server.get_messages(data);
        REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
        REQUIRE_FALSE(messages_it.begin()->error());
        REQUIRE(messages_it.begin()->payload.size() == 2);
        REQUIRE(messages_it.begin()->payload[0] == "00000000000000000000000000000000000000000000000000");
        REQUIRE(messages_it.begin()->payload[1] == "00000000000000000000000000000000000000000000000000");
    }
}
