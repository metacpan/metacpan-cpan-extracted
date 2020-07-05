#include <catch.hpp>
#include <vector>
#include <xs/protocol/websocket.h>
#include <panda/encode/base16.h>
#include <panda/encode/base64.h>

using namespace panda;
using namespace panda::protocol::websocket;

template <typename T>
string to_string(T range) {
    string r;
    for (const string& s : range) r += s;
    return r;
}

TEST_CASE("FrameSender & Message builder", "[deflate-extension]") {
    Parser::Config cfg;
    cfg.deflate->compression_threshold = 0;

    ServerParser server;
    server.configure(cfg);
    ClientParser client;

    ConnectRequestSP connect_request(new ConnectRequest());
    connect_request->uri = new URI("ws://crazypanda.ru");
    connect_request->ws_key = "dGhlIHNhbXBsZSBub25jZQ==";
    connect_request->ws_version = 13;
    connect_request->ws_protocol = "ws";
    auto client_request = client.connect_request(connect_request);

    REQUIRE((bool)server.accept(client_request));
    auto server_reply = server.accept_response();
    client.connect(server_reply);

    REQUIRE(server.established());
    REQUIRE(client.established());
    REQUIRE(server.is_deflate_active());
    REQUIRE(client.is_deflate_active());

    SECTION("FrameBuffer") {

        SECTION("send (iterator)") {
            std::vector<string> fragments;
            fragments.push_back("hello");
            fragments.push_back(" world");
            auto data = server.start_message(DeflateFlag::YES).send(fragments.begin(), fragments.end(), true);
            auto data_string = to_string(data);
            auto messages_it = client.get_messages(data_string);
            REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
            REQUIRE(messages_it.begin()->payload[0] == "hello world");
        }

        SECTION("send (iterator, empty)") {
            std::vector<string> fragments;
            auto data = server.start_message(DeflateFlag::YES).send(fragments.begin(), fragments.end(), true);
            auto data_string = to_string(data);
            auto messages_it = client.get_messages(data_string);
            REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
            REQUIRE(messages_it.begin()->payload.empty());
        }

        SECTION("send (iterator with holes)") {
            std::vector<string> fragments;
            fragments.push_back("");
            fragments.push_back("hello");
            fragments.push_back("");
            fragments.push_back(" world");
            fragments.push_back("");
            auto data = server.start_message(DeflateFlag::YES).send(fragments.begin(), fragments.end(), true);
            auto data_string = to_string(data);
            auto messages_it = client.get_messages(data_string);
            REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
            auto it = messages_it.begin();
            REQUIRE(it->payload.size() == 1);
            REQUIRE(it->payload[0] == "hello world");
        }

        SECTION("send with zero shared-capacity last buff") {
            // some png piece
            unsigned const char buff[] = {
                0x03, 0x6c, 0x01, 0x8b, 0xfe, 0xd6, 0xd7, 0x16,
                0xb0, 0xe8, 0x7f, 0x1d, 0x6d, 0x01, 0x8b, 0x3e,
                0xea, 0x65, 0x0b, 0x58, 0xf4, 0x5d, 0x17, 0x5b,
                0xc0, 0xa2, 0x8d, 0xae, 0xdb, 0x02, 0x16, 0x6d,
                0x77, 0xd1, 0x16, 0xb0, 0x68, 0xb7, 0x2b, 0xb6,
                0x80, 0x45, 0x47, 0x35, 0xdb, 0x02, 0x16, 0x9d,
                0xd4, 0x66, 0x0b, 0x58, 0x74, 0x5e, 0x83, 0x2d,
                0x60, 0x51, 0x51, 0xb5, 0xb6, 0x80, 0x45, 0xa5,
                0x55, 0xd9, 0x02, 0x16, 0x55, 0x54, 0x6e, 0x0b,
                0x58, 0x54, 0x57, 0xa1, 0x2d, 0x60, 0x51, 0x75,
                0x25, 0xb6, 0x80, 0x45, 0x2d, 0x9d, 0xda, 0x02,
                0x16, 0x35, 0x76, 0x6c, 0x0b, 0x58, 0xd4, 0xde,
                0x81, 0x2d, 0x60, 0xd1, 0xa5, 0xf6, 0x6c, 0x01,
                0x8b, 0xae, 0xb6, 0x69, 0x0b, 0x58, 0xd4, 0xa1,
                0x5f, 0x5b, 0xc0, 0xa2, 0x3e, 0x7d, 0xd9, 0x02,
                0x16, 0x75, 0xeb, 0xdd, 0x16, 0xb0, 0xa8, 0x67,
                0x2f, 0x5b, 0xc0, 0xa2, 0xce, 0x3d, 0x6d, 0xdd,
                0x1e, 0xab, 0x5f, 0x07, 0x85, 0x8c, 0xdf, 0x58,
                0x34, 0xa4, 0x3f, 0x0d, 0x82, 0x2c, 0x9c, 0x00,
                0x25, 0xe0, 0x67, 0x00, 0x00, 0x00, 0x00, 0x49,
                0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82, 0x00
            };
            std::vector<string> fragments;
            fragments.emplace_back(reinterpret_cast<const char*>(buff), sizeof(buff));
            const char* buff_23 = "12345678901234567890123";
            string sso_23(buff_23);
            fragments.emplace_back(sso_23.substr(23, 0));
            REQUIRE(bool(fragments.back().shared_buf())); // bool to prevent Catch printing data
            REQUIRE(fragments.back().shared_capacity() == 0);
            auto data = server.start_message(DeflateFlag::YES).send(fragments.begin(), fragments.end(), true);
            auto data_string = to_string(data);
            auto messages_it = client.get_messages(data_string);
            REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
            auto it = messages_it.begin();
            REQUIRE(it->payload.size() == 1);
            REQUIRE(it->payload[0].size() >= sizeof(buff));
        }
    }


    SECTION("MessageBuilder") {
        SECTION("MessageBuilder::send (fragmented message iterator)") {
            std::vector<string> fragments;
            fragments.push_back("hello");
            fragments.push_back(" world");
            auto data = server.message().send(fragments.begin(), fragments.end());
            auto data_string = to_string(data);
            auto messages_it = client.get_messages(data_string);
            REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
            REQUIRE(messages_it.begin()->payload[0] == "hello world");
        }

        SECTION("MessageBuilder::send (fragmented message iterator, hole in the middle)") {
            std::vector<string> fragments;
            fragments.push_back("hello");
            fragments.push_back("");
            fragments.push_back("");
            fragments.push_back(" world");
            auto data = server.message().send(fragments.begin(), fragments.end());
            auto data_string = to_string(data);
            auto messages_it = client.get_messages(data_string);
            REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
            REQUIRE(messages_it.begin()->payload[0] == "hello world");
        }

        SECTION("MessageBuilder::send (empty string)") {
            panda::string item = "";
            auto data = server.message().send(item);
            auto data_string = to_string(data);
            auto messages_it = client.get_messages(data_string);
            REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
            REQUIRE(messages_it.begin()->payload.size() == 0);
        }

        SECTION("MessageBuilder::send (fragmented message iterator, empty)") {
            std::vector<string> fragments;
            fragments.push_back("");
            auto data = server.message().send(fragments.begin(), fragments.end());
            auto data_string = to_string(data);
            auto messages_it = client.get_messages(data_string);
            REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
            REQUIRE(messages_it.begin()->payload.size() == 0);
        }

        SECTION("MessageBuilder::send (fragmented multi-frame iterator, 1 fragment)") {
            std::vector<std::vector<string>> pieces;

            std::vector<string> fragments1;
            fragments1.push_back("hello");
            fragments1.push_back(" world!");
            pieces.push_back(fragments1);


            auto builder = server.message();
            auto data = builder.deflate(true).send(pieces.begin(), pieces.end());
            auto data_string = to_string(data);
            REQUIRE(data_string != "hello world!");
            auto messages_it = client.get_messages(data_string);
            REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);

            auto it = messages_it.begin();
            REQUIRE(it->payload[0] == "hello world!");
        }

        SECTION("MessageBuilder::send (fragmented multi-frame iterator, 2 fragments)") {
            std::vector<std::vector<string>> pieces;

            std::vector<string> fragments1;
            fragments1.push_back("hello");
            fragments1.push_back(" world!");
            pieces.push_back(fragments1);

            std::vector<string> fragments2;
            fragments2.push_back(" Let's do ");
            fragments2.push_back("some testing");
            pieces.push_back(fragments2);

            auto builder = server.message();
            auto data = builder.deflate(true).send(pieces.begin(), pieces.end());
            auto data_string = to_string(data);
            REQUIRE(data_string.find("hello") == std::string::npos);
            auto messages_it = client.get_messages(data_string);
            REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);

            auto it = messages_it.begin();
            REQUIRE(it->payload.size() == 2);
            REQUIRE(it->payload[0] == "hello world!");
            REQUIRE(it->payload[1] == " Let's do some testing");
        }

        SECTION("MessageBuilder::send (fragmented multi-frame iterator, 2 fragments, last empty)") {
            std::vector<std::vector<string>> pieces;

            std::vector<string> fragments1;
            fragments1.push_back("hello");
            fragments1.push_back(" world!");
            pieces.push_back(fragments1);

            std::vector<string> fragments2;
            pieces.push_back(fragments2);

            auto builder = server.message();
            auto data = builder.deflate(true).send(pieces.begin(), pieces.end());
            auto data_string = to_string(data);
            REQUIRE(data_string.find("hello") == std::string::npos);
            auto messages_it = client.get_messages(data_string);
            REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);

            auto it = messages_it.begin();
            REQUIRE(it->payload.size() == 1);
            REQUIRE(it->payload[0] == "hello world!");
        }

        SECTION("MessageBuilder::send (fragmented multi-frame iterator, 4 fragments, empty middle)") {
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

            auto builder = server.message();
            auto data = builder.deflate(true).send(pieces.begin(), pieces.end());
            auto data_string = to_string(data);
            REQUIRE(data_string.find("hello") == std::string::npos);
            auto messages_it = client.get_messages(data_string);
            REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);

            auto it = messages_it.begin();
            REQUIRE(it->payload.size() == 2);
            REQUIRE(it->payload[0] == "hello world");
            REQUIRE(it->payload[1] == "!");
        }

        SECTION("MessageBuilder::send (fragmented multi-frame iterator, 2 fragments, both empty)") {
            std::vector<std::vector<string>> pieces;

            std::vector<string> fragments1;
            pieces.push_back(fragments1);

            std::vector<string> fragments2;
            pieces.push_back(fragments2);

            auto builder = server.message();
            auto data = builder.deflate(true).send(pieces.begin(), pieces.end());
            auto data_string = to_string(data);
            REQUIRE(data_string.find("hello") == std::string::npos);
            auto messages_it = client.get_messages(data_string);
            REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);

            auto it = messages_it.begin();
            REQUIRE(it->payload.empty());
        }
    }

    SECTION("empty compressed frame with zero payload") {
        string payload;
        REQUIRE(payload.length() == 0);
        //auto builder =
        auto data = server.start_message(DeflateFlag::YES).send(payload, true);
        auto it = std::begin(data) + 1;
        REQUIRE((*it).length() == 1);
        REQUIRE((*it).capacity() >= ((*it).length()));
        auto data_string = to_string(data);
        REQUIRE(data_string.length() == 3);

        SECTION("zero uncompressed payload") {
            auto messages_it = client.get_messages(data_string);
            REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
            REQUIRE(messages_it.begin()->payload_length() == 0);
        }

        SECTION("non-zero network payload") {
            auto frames_it = client.get_frames(data_string);
            REQUIRE(std::distance(frames_it.begin(), frames_it.end()) == 1);
            REQUIRE(frames_it.begin()->payload_length() == 1);
        }
    }


    SECTION("compressed frame with zero payload") {
        string payload;
        REQUIRE(payload.length() == 0);
        FrameHeader fh(Opcode::TEXT, true, true, false, false, true, (uint32_t)std::rand());
        auto data_string = Frame::compile(fh, payload);
        auto messages_it = client.get_messages(data_string);
        REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
        REQUIRE(messages_it.begin()->payload_length() == 0);
    }

    SECTION("Control compressed frame") {
        string payload;
        FrameHeader fh(Opcode::PING, true, true, false, false, true, (uint32_t)std::rand());
        auto data_string = Frame::compile(fh, payload);
        auto frames_it = client.get_frames(data_string);
        REQUIRE(frames_it.begin()->error & errc::control_frame_compression);
    }

    SECTION("send compressed frame bigger then original") {
        string payload = encode::decode_base16("8e008f8f8f0090909000919191009292");
        string payload_copy = payload;

        auto data = server.start_message(DeflateFlag::YES).send(payload, true);
        auto it = std::begin(data) + 1;
        REQUIRE((*it).length() == 24);
        auto data_string = to_string(data);
        auto messages_it = client.get_messages(data_string);
        REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
        REQUIRE_FALSE(messages_it.begin()->error);
        REQUIRE(messages_it.begin()->payload[0] == payload_copy);
    }

    SECTION("SRV-1236") {
        SECTION("buggy sample (does work)") {
            string data_sample = "UlBQUDLWM1eyUqjmUoABpaTUjMSyzPwioLCSv7eSDhYp55z84lQs8imlRYklmfl5QCkjZPGi1Nz8klSwLuf8FJBOQwMDNBUF+UUlaZk5YGMTS0vykxIz8goqSzLy8+IN4s2AODmxODXeON5cL6sYaANUby3MECUTPUM9Q9K8AgAAAP//";
            string payload = encode::decode_base64(data_sample);
            FrameHeader fh(Opcode::TEXT, true, true, false, false, true, (uint32_t)std::rand());
            auto data_string = Frame::compile(fh, payload).append(payload);
            auto messages_it = server.get_messages(data_string);
            REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
            REQUIRE(!messages_it.begin()->error);
        }
    }

    SECTION("zlib test") {
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
}


TEST_CASE("SRV-1236",  "[deflate-extension]") {
    Parser::Config cfg;
    cfg.deflate->client_no_context_takeover = true;

    ServerParser server;
    server.configure(cfg);
    ClientParser client;

    ConnectRequestSP connect_request(new ConnectRequest());
    connect_request->uri = new URI("ws://crazypanda.ru");
    connect_request->ws_key = "dGhlIHNhbXBsZSBub25jZQ==";
    connect_request->ws_version = 13;
    connect_request->ws_protocol = "ws";
    auto client_request = client.connect_request(connect_request);

    REQUIRE((bool)server.accept(client_request));
    auto server_reply = server.accept_response();
    client.connect(server_reply);

    REQUIRE(server.established());
    REQUIRE(client.established());
    REQUIRE(server.is_deflate_active());
    REQUIRE(client.is_deflate_active());

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
            auto data_string = Frame::compile(fh, payload).append(payload);
            auto messages_it = server.get_messages(data_string);
            REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
            REQUIRE_FALSE(messages_it.begin()->error);
        }
    }

    SECTION("12.1.11 (no rsv1 flag on 2nd frame == that's correct)") {
        string payload1 = encode::decode_base64("MjAgFQAAAAD//w");
        string payload2 = encode::decode_base64("Ih0AAAAA//8");

        FrameHeader fh1(Opcode::TEXT, false, true, false, false, true, (uint32_t)std::rand());
        auto data_string1 = Frame::compile(fh1, payload1).append(payload1);

        FrameHeader fh2(Opcode::CONTINUE, true, false, false, false, true, (uint32_t)std::rand());
        auto data_string2 = Frame::compile(fh2, payload2).append(payload2);
        auto data_string = data_string1 + data_string2;

        auto messages_it = server.get_messages(data_string);
        REQUIRE(std::distance(messages_it.begin(), messages_it.end()) == 1);
        REQUIRE_FALSE(messages_it.begin()->error);
        REQUIRE(messages_it.begin()->payload.size() == 2);
        REQUIRE(messages_it.begin()->payload[0] == "00000000000000000000000000000000000000000000000000");
        REQUIRE(messages_it.begin()->payload[1] == "00000000000000000000000000000000000000000000000000");
    }

}
