#include "../test.h"

#define TEST(name) TEST_CASE("send-control: " name, "[send-control]")

TEST("send_control PING") {
    EstablishedServerParser p;
    SECTION("empty") {
        auto bin = p.send_control(Opcode::PING);
        CHECK_BINFRAME(bin).final().opcode(Opcode::PING).binlen(2);
    }
    SECTION("with payload") {
        auto pl = repeat("h", 125);
        auto bin = p.send_control(Opcode::PING, pl);
        CHECK_BINFRAME(bin).final().opcode(Opcode::PING).payload(pl).binlen(127);
    }
    SECTION("long payload") {
        auto bin = p.send_control(Opcode::PING, repeat("h", 126));
        CHECK_BINFRAME(bin).final().opcode(Opcode::PING).payload(repeat("h", 125)).binlen(127);
    }
}

TEST("send_control PONG") {
    EstablishedServerParser p;
    SECTION("empty") {
        auto bin = p.send_control(Opcode::PONG);
        CHECK_BINFRAME(bin).final().opcode(Opcode::PONG).binlen(2);
    }
    SECTION("with payload") {
        auto bin = p.send_control(Opcode::PONG, "hi there");
        CHECK_BINFRAME(bin).final().opcode(Opcode::PONG).payload("hi there").binlen(10);
    }
    SECTION("long payload") {
        auto bin = p.send_control(Opcode::PONG, repeat("h", 126));
        CHECK_BINFRAME(bin).final().opcode(Opcode::PONG).payload(repeat("h", 125)).binlen(127);
    }
}

TEST("send_control CLOSE") {
    EstablishedServerParser p;
    SECTION("empty") {
        auto bin = p.send_control(Opcode::CLOSE);
        CHECK_BINFRAME(bin).final().opcode(Opcode::CLOSE).binlen(2);
    }
    SECTION("can't send after CLOSE sent") {
        p.send_control(Opcode::CLOSE);
        CHECK_THROWS_AS(p.start_message().send("aaa"), Error);
    }
    SECTION("can send after reset") {
        p.send_control(Opcode::CLOSE);
        reset(p);
        p.start_message().send("aaa");
    }
    SECTION("with payload") {
        auto bin = p.send_control(Opcode::CLOSE, "hi there");
        CHECK_BINFRAME(bin).final().opcode(Opcode::CLOSE).payload("hi there").binlen(10);
    }
    SECTION("long payload") {
        auto bin = p.send_control(Opcode::CLOSE, repeat("h", 126));
        CHECK_BINFRAME(bin).final().opcode(Opcode::CLOSE).payload(repeat("h", 125)).binlen(127);
    }
}

TEST("send_ping") {
    EstablishedServerParser p;
    SECTION("empty") {
        auto bin = p.send_ping();
        CHECK_BINFRAME(bin).final().opcode(Opcode::PING).binlen(2);
    }
    SECTION("with payload") {
        auto bin = p.send_ping("hi buddy");
        CHECK_BINFRAME(bin).final().opcode(Opcode::PING).payload("hi buddy").binlen(10);
    }
    SECTION("long payload") {
        auto bin = p.send_ping(repeat("h", 126));
        CHECK_BINFRAME(bin).final().opcode(Opcode::PING).payload(repeat("h", 125)).binlen(127);
    }
}

TEST("send_pong") {
    EstablishedServerParser p;
    SECTION("empty") {
        auto bin = p.send_pong();
        CHECK_BINFRAME(bin).final().opcode(Opcode::PONG).binlen(2);
    }
    SECTION("with payload") {
        auto bin = p.send_pong("hi buddy");
        CHECK_BINFRAME(bin).final().opcode(Opcode::PONG).payload("hi buddy").binlen(10);
    }
    SECTION("long payload") {
        auto bin = p.send_pong(repeat("h", 126));
        CHECK_BINFRAME(bin).final().opcode(Opcode::PONG).payload(repeat("h", 125)).binlen(127);
    }
}

TEST("send_close") {
    EstablishedServerParser p;
    SECTION("empty") {
        auto bin = p.send_close();
        CHECK_BINFRAME(bin).final().opcode(Opcode::CLOSE).binlen(2);
    }
    SECTION("with code") {
        auto bin = p.send_close(CloseCode::DONE);
        CHECK_BINFRAME(bin).final().opcode(Opcode::CLOSE).close_code(CloseCode::DONE).binlen(4);
    }
    SECTION("with code and payload") {
        auto bin = p.send_close(CloseCode::AWAY, repeat("f", 123));
        CHECK_BINFRAME(bin).final().opcode(Opcode::CLOSE).close_code(CloseCode::AWAY).payload(repeat("f", 123)).binlen(127);
    }
    SECTION("with code and long payload") {
        auto bin = p.send_close(CloseCode::AWAY, repeat("f", 127));
        CHECK_BINFRAME(bin).final().opcode(Opcode::CLOSE).close_code(CloseCode::AWAY).payload(repeat("f", 123)).binlen(127);
    }
}

TEST("control frames do not reset message state in frame mode") {
    EstablishedServerParser p;
    auto builder = p.start_message(DeflateFlag::NO);
    auto bin = builder.send("frame1");
    CHECK_BINFRAME(bin).opcode(Opcode::BINARY).payload("frame1");
    p.send_control(Opcode::PING);
    p.send_control(Opcode::PONG);
    p.send_ping();
    p.send_pong();
    bin = builder.send("frame2");
    CHECK_BINFRAME(bin).opcode(Opcode::CONTINUE).payload("frame2");
    p.send_control(Opcode::PING);
    p.send_control(Opcode::PONG);
    p.send_ping();
    p.send_pong();
    bin = builder.send("frame3", IsFinal::YES);
    CHECK_BINFRAME(bin).final().opcode(Opcode::CONTINUE).payload("frame3");
}

TEST("control frames from client get masked") {
    EstablishedClientParser p;
    auto bin = p.send_ping();
    CHECK_BINFRAME(bin).final().opcode(Opcode::PING).mask(bin.substr(2, 4)).binlen(6);
}
