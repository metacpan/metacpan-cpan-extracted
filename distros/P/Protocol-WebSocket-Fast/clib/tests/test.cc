#include "test.h"
#include <regex>
#include <ctype.h>
#include <panda/log.h>
#include <panda/endian.h>

namespace test {

//static bool _init () {
//    panda::log::set_level(panda::log::Level::Warning);
//    panda::log::set_logger([](auto& msg, auto&) {
//        fprintf(stderr, "%s\n", msg.c_str());
//    });
//    return true;
//}
//static bool __init = _init();

bool ReMatcher::match (const string& matchee) const {
    auto flags = std::regex::ECMAScript;
    if (case_sen) flags |= std::regex::icase;
    auto reg = std::regex((std::string)re, flags);
    return std::regex_search((std::string)matchee, reg);
}

std::string ReMatcher::describe () const {
    return "matches " + ::Catch::Detail::stringify(re) + (case_sen ? " case sensitively" : " case insensitively");
}

void regex_replace (string& str, const std::string& re, const std::string& fmt) {
    str = string(std::regex_replace((std::string)str, std::regex(re, std::regex::ECMAScript|std::regex::icase), fmt));
}

string repeat (string_view s, int times) {
    string ret;
    ret.reserve(s.length() * times);
    for (int i = 0; i < times; ++i) ret += s;
    return ret;
}

std::vector<string> FrameGenerator::vec () const {
    if (!_msg_mode) throw std::runtime_error("vector return is only for message mode");
    return _gen_message();
}

string FrameGenerator::str () const {
    return _msg_mode ? join(_gen_message()) : _gen_frame();
}

static void crypt_xor (string& str, string_view key) {
    auto buf  = (unsigned char*)str.buf();
    auto kbuf = (unsigned char*)key.data();
    auto slen = str.length();
    auto klen = key.length();
    for (size_t i = 0; i < slen; ++i) buf[i] ^= kbuf[i % klen];
}

string FrameGenerator::_gen_frame () const {
    uint8_t first = 0, second = 0;

    for (auto v : {_final, _rsv1, _rsv2, _rsv3}) {
        first |= v ? 1 : 0;
        first <<= 1;
    }

    first <<= 3;
    first |= ((int)_opcode & 15);

    second |= _mask ? 1 : 0;
    second <<= 7;

    auto data = _payload;

    if (_close_code) {
        auto net_cc = h2be16(_close_code);
        data = string((char*)&net_cc, 2) + data;
    }

    auto dlen = data.length();
    string extlen;
    if (dlen < 126) {
        second |= dlen;
    }
    else if (dlen < 65536) {
        second |= 126;
        auto net_len = h2be16(dlen);
        extlen.assign((char*)&net_len, 2);
    }
    else {
        second |= 127;
        auto net_len = h2be64(dlen);
        extlen.assign((char*)&net_len, 8);
    }

    auto mask = _mask;
    if (mask.length()) {
        if (mask.length() != 4) {
            auto rnd = h2be32(rand());
            mask.assign((char*)&rnd, 4);
        }
        crypt_xor(data, mask);
    }

    return string() + (char)first + (char)second + extlen + mask + data;
}

std::vector<string> FrameGenerator::_gen_message () const {
    FrameGenerator g = *this;
    auto nframes  = _nframes ? _nframes : 1;
    auto opcode   = _opcode;
    auto payload  = _payload;
    std::vector<string> ret;

    FrameGenerator gen = *this;
    auto frames_left = nframes;
    while (frames_left) {
        auto curlen = payload.length() / frames_left--;
        auto chunk = payload.substr(0, curlen);
        if (chunk.length() >= curlen) payload.offset(curlen);
        else payload.clear();

        ret.push_back(
            gen.opcode(opcode)
               .payload(chunk)
               .final(payload.empty())
               .mask(_mask)
               ._gen_frame()
        );
        opcode = Opcode::CONTINUE;
    }

    return ret;
}

std::vector<string> accept_packet () {
    return {
        "GET /?encoding=text HTTP/1.1\r\n",
        "Host: dev.crazypanda.ru:4680\r\n",
        "Connection: Upgrade\r\n",
        "Pragma: no-cache\r\n",
        "Cache-Control: no-cache\r\n",
        "Upgrade: websocket\r\n",
        "Origin: http://www.websocket.org\r\n",
        "Sec-WebSocket-Version: 13\r\n",
        "User-Agent: Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36\r\n",
        "Accept-Encoding: gzip, deflate, sdch\r\n",
        "Accept-Language: ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4\r\n",
        "Cookie: _ga=GA1.2.1700804447.1456741171\r\n",
        "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n",
        "Sec-WebSocket-Protocol: chat\r\n",
        "Sec-WebSocket-Extensions: permessage-deflate; client_max_window_bits=15; server_max_window_bits=15\r\n",
        "\r\n",
    };
}

static void _establish_server (ServerParser& p) {
    auto str = accept_packet_s();
    auto res = p.accept(str);
    if (!res) throw std::runtime_error("should not happen");
    p.accept_response();
    if (!p.established()) throw std::runtime_error("should not happen");
}

static void _establish_client (ClientParser& p) {
    auto cstr = p.connect_request(ConnectRequest::Builder().uri("ws://jopa.ru").build());
    ServerParser sp;
    if (!sp.accept(cstr)) throw std::runtime_error("should not happen");
    if (!sp.accepted()) throw std::runtime_error("should not happen");
    auto rstr = sp.accept_response();
    if (!p.connect(rstr)) throw std::runtime_error("should not happen");
    if (!p.established()) throw std::runtime_error("should not happen");
}

EstablishedServerParser::EstablishedServerParser (const Parser::Config& cfg, bool deflate) : ServerParser(cfg) {
    if (!deflate) no_deflate();
    _establish_server(*this);
}

EstablishedClientParser::EstablishedClientParser (const Parser::Config& cfg, bool deflate) : ClientParser(cfg) {
    if (!deflate) no_deflate();
    _establish_client(*this);
}

void reset (Parser& p) {
    p.reset();
    if (p.established()) throw std::runtime_error("should not happen");
    if (dynamic_cast<ServerParser*>(&p)) _establish_server(dynamic_cast<ServerParser&>(p));
    else                                 _establish_client(dynamic_cast<ClientParser&>(p));
}

FMChecker::~FMChecker () noexcept(false) {
    if (_frame) {
        CHECK_FALSE(_frame->error());
        if (_opcode) {
            CHECK(_frame->opcode() == _opcode.value());
            CHECK(_frame->is_control() == (_opcode.value() >= Opcode::CLOSE));
        }
        if (_fin)           CHECK(_frame->final() == _fin.value());
        if (_rsv1)          CHECK(_frame->rsv1() == _rsv1.value());
        if (_rsv2)          CHECK(_frame->rsv1() == _rsv2.value());
        if (_rsv3)          CHECK(_frame->rsv1() == _rsv3.value());
        if (_payload)       CHECK(join(_frame->payload) == _payload.value());
        if (_paylen)        CHECK(_frame->payload_length() == _paylen.value());
        if (_close_code)    CHECK(_frame->close_code() == _close_code.value());
        if (_close_message) CHECK(_frame->close_message() == _close_message.value());
    } else {
        if (_opcode) {
            CHECK(_message->opcode() == _opcode.value());
            CHECK(_message->is_control() == (_opcode.value() >= Opcode::CLOSE));
        }
        if (_payload)       CHECK(join(_message->payload) == _payload.value());
        if (_paylen)        CHECK(_message->payload_length() == _paylen.value());
        if (_close_code)    CHECK(_message->close_code() == _close_code.value());
        if (_close_message) CHECK(_message->close_message() == _close_message.value());
        if (_nframes)       CHECK(_message->frame_count() == _nframes.value());

    }
}

FrameGenerator::~FrameGenerator () noexcept(false) {
    if (!_bin) return;
    if (_binlen) CHECK(_bin.length() == _binlen);
    // TODO: check in a printable way
    CHECK((_bin == str()));
}

void test_frame (Parser& p, FrameGenerator f, const ErrorCode& error, int suggested_close_code) {
    auto bin = f.str();
    auto opcode = f.opcode();
    std::vector<FrameSP> frames;

    SECTION("whole buffer") {
        frames = get_frames(p, bin);
    }

    SECTION("buffer by char") {
        while (bin.length() && !frames.size()) {
            auto chr = bin.substr(0, 1);
            bin.offset(1);
            frames = get_frames(p, chr);
        }
        if (!error) CHECK(!bin.length());
    }

    CHECK(frames.size() == 1);
    auto frame = frames.front();

    if (error) {
        CHECK(frame->error() == error);
        if (suggested_close_code) CHECK(p.suggested_close_code() == suggested_close_code);
    } else {
        CHECK_FALSE(frame->error());
        CHECK(frame->opcode() == opcode);
        CHECK(frame->is_control() == (opcode >= Opcode::CLOSE));
        CHECK(frame->final() == f.is_final());
        CHECK(frame->payload_length() == f.payload().length());
        CHECK((join(frame->payload) == f.payload()));
        if (f.close_code()) CHECK(frame->close_code() == f.close_code());
    }
}

MessageSP test_message (Parser& p, FrameGenerator f, const ErrorCode& error) {
    auto opcode = f.opcode();
    auto nframes = f.nframes() ? f.nframes() : 1;
    if (opcode < Opcode::CLOSE) f.msg_mode();

    auto bin = f.str();
    std::vector<MessageSP> messages;

    SECTION("whole buffer") {
        messages = get_messages(p, bin);
    }

    SECTION("buffer by char") {
        while (bin.length() && !messages.size()) {
            auto chr = bin.substr(0, 1);
            bin.offset(1);
            messages = get_messages(p, chr);
        }
        if (!error) CHECK(!bin.length());
    }

    CHECK(messages.size() == 1);
    auto message = messages.front();

    if (error) {
        CHECK(message->error() == error);
    } else {
        CHECK_FALSE(message->error());
        CHECK(message->opcode() == opcode);
        CHECK(message->is_control() == (opcode >= Opcode::CLOSE));
        CHECK(message->payload_length() == f.payload().length());
        CHECK((join(message->payload) == f.payload()));
        if (f.close_code()) CHECK(message->close_code() == f.close_code());
        if (f.close_code_check()) CHECK(message->close_code() == f.close_code_check());
        CHECK(message->frame_count() == nframes);
    }

    return message;
}

}
