#include "../test.h"

#define TEST(name) TEST_CASE("send-frame: " name, "[send-frame]")

TEST("server -> client frame") {
    EstablishedServerParser p;

    SECTION("small frame") {
        string payload = "preved"; // must be <= 125
        auto bin = p.start_message().send(payload, IsFinal::YES);
        CHECK_BINFRAME(bin).final().opcode(Opcode::BINARY).payload(payload).binlen(2 + 6); // 2 header + 6 payload
        std::vector<string> vpl = {"pr", "ev", "ed"};
        auto bin2 = p.start_message().send(vpl.begin(), vpl.end(), IsFinal::YES);
        CHECK((bin2 == bin)); // check iterator mode
    }

    SECTION("medium frame") {
        string payload = repeat("preved", 100); // must be: 125 < X < 65536
        auto bin = p.start_message().send(payload, IsFinal::YES);
        CHECK_BINFRAME(bin).final().opcode(Opcode::BINARY).payload(payload).binlen(2 + 2 + 600); // 2 header + 2 length + 600 payload
    }

    SECTION("big frame") {
        string payload = repeat("preved!", 10000); // must be > 65536
        auto bin = p.start_message().send(payload, IsFinal::YES);
        CHECK_BINFRAME(bin).final().opcode(Opcode::BINARY).payload(payload).binlen(2 + 8 + 70000);
    }
}

TEST("client -> server frame") {
    EstablishedClientParser p;

    SECTION("small frame") {
        string payload = "preved"; // must be <= 125
        auto bin = p.start_message(Opcode::TEXT).send(payload, IsFinal::YES);
        CHECK_BINFRAME(bin).mask(bin.substr(2, 4)).final().opcode(Opcode::TEXT).payload(payload).binlen(2 + 4 + 6); // 2 header + 4 mask + 6 payload

        EstablishedServerParser p;
        auto f = get_frame(p, bin);
        CHECK_FRAME(f).final().payload(payload);
    }

    SECTION("medium frame") {
        string payload = repeat("preved", 100); // must be: 125 < X < 65536
        auto bin = p.start_message(Opcode::TEXT).send(payload, IsFinal::YES);
        CHECK_BINFRAME(bin).mask(bin.substr(4, 4)).final().opcode(Opcode::TEXT).payload(payload).binlen(2 + 2 + 4 + 600); // 2 header + 2 length + 4 mask + 600 payload
    }

    SECTION("big frame") {
        string payload = repeat("preved!", 10000); // must be > 65536
        auto bin = p.start_message(Opcode::TEXT).send(payload, IsFinal::YES);
        CHECK_BINFRAME(bin).mask(bin.substr(10, 4)).final().opcode(Opcode::TEXT).payload(payload).binlen(2 + 8 + 4 + 70000);
    }
}

TEST("empty frame still masked") {
    EstablishedClientParser p;
    auto bin = p.start_message(Opcode::BINARY).send("", IsFinal::YES);
    CHECK_BINFRAME(bin).mask(bin.substr(2, 4)).final().opcode(Opcode::BINARY).binlen(2 + 4);
}

TEST("opcode CONTINUE is forced for fragment frames of message (including final frame)") {
    EstablishedServerParser p;
    auto m1 = p.start_message(Opcode::BINARY);
    auto bin = m1.send("frame1");
    CHECK_BINFRAME(bin).opcode(Opcode::BINARY).payload("frame1");
    bin = m1.send("frame2");
    CHECK_BINFRAME(bin).opcode(Opcode::CONTINUE).payload("frame2");
    bin = m1.send("frame3", IsFinal::YES);
    CHECK_BINFRAME(bin).final().opcode(Opcode::CONTINUE).payload("frame3");

    auto m2 = p.start_message(Opcode::TEXT);
    bin = m2.send("frame4");
    CHECK_BINFRAME(bin).opcode(Opcode::TEXT).payload("frame4");
    bin = m2.send("frame5", IsFinal::YES); // reset frame count
    CHECK_BINFRAME(bin).final().opcode(Opcode::CONTINUE).payload("frame5");
}

TEST("control frame send") {
    EstablishedServerParser p;
    auto bin = p.send_control(Opcode::PING, "myping");
    CHECK_BINFRAME(bin).final().opcode(Opcode::PING).payload("myping");
    bin = p.send_control(Opcode::PONG, "mypong");
    CHECK_BINFRAME(bin).final().opcode(Opcode::PONG).payload("mypong");
    bin = p.send_control(Opcode::CLOSE, "myclose");
    CHECK_BINFRAME(bin).final().opcode(Opcode::CLOSE).payload("myclose");
}

TEST("frame count survives control message in the middle") {
    EstablishedServerParser p;
    auto m = p.start_message();
    auto bin = m.send("frame1");
    CHECK_BINFRAME(bin).opcode(Opcode::BINARY).payload("frame1");
    bin = p.send_control(Opcode::PING, "");
    CHECK_BINFRAME(bin).final().opcode(Opcode::PING);
    bin = m.send("frame2");
    CHECK_BINFRAME(bin).opcode(Opcode::CONTINUE).payload("frame2");
    bin = p.send_control(Opcode::PONG, "");
    CHECK_BINFRAME(bin).final().opcode(Opcode::PONG);
    bin = m.send("frame3", IsFinal::YES);
    CHECK_BINFRAME(bin).final().opcode(Opcode::CONTINUE).payload("frame3");
}

TEST("attempt to send frame after sending final frame") {
    EstablishedServerParser p;
    auto m = p.start_message();
    auto bin = m.send("payload", IsFinal::YES);
    CHECK(!bin.empty());
    REQUIRE_THROWS_AS(m.send("beyond payload", IsFinal::YES), Error);
    REQUIRE_THROWS_AS(m.send("beyond payload", IsFinal::NO), Error);
}

TEST("attempt to start another message, having unfinished one") {
    EstablishedServerParser p;
    auto m = p.start_message();
    REQUIRE_THROWS_AS(p.start_message(), Error);
    m.send("hello ");
    REQUIRE_THROWS_AS(p.start_message(), Error);
    m.send("world", IsFinal::YES);
    REQUIRE_NOTHROW(p.start_message());
};
