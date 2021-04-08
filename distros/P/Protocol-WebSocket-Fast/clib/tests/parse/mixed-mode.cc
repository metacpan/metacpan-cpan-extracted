#include "../test.h"

#define TEST(name) TEST_CASE("parse-mixed-mode: " name, "[parse-mixed-mode]")

TEST("frame + message") {
    EstablishedServerParser p;
    auto bin = gen_message().mask().payload("iframe").str() +
               gen_message().mask().payload("imessage").str();
    auto frange = p.get_frames(bin);
    REQUIRE(frange.begin() != frange.end());
    CHECK_FRAME(*frange.first).payload("iframe");
    auto mrange = p.get_messages();
    CHECK(++frange.first == frange.end()); // previous iterator invalidated
    CHECK_MESSAGE(*mrange.first).nframes(1).payload("imessage");
    CHECK(++mrange.first == mrange.end()); // nothing more
}

TEST("message + frame") {
    EstablishedServerParser p;
    auto bin = gen_message().mask().payload("imessage2").str() +
               gen_message().mask().payload("iframe2").str();
    auto mrange = p.get_messages(bin);
    CHECK_MESSAGE(*mrange.begin()).nframes(1).payload("imessage2");
    auto frange = p.get_frames();
    CHECK(++mrange.first == mrange.end()); // previous iterator invalidated
    CHECK_FRAME(*frange.begin()).payload("iframe2");
    CHECK(++frange.first == frange.end()); // nothing more
}

TEST("1x2 frame + message") {
    EstablishedServerParser p;
    auto bin = gen_message().mask().payload("part1part2").nframes(2).str() +
               gen_message().mask().payload("msg").str();

    SECTION("2 frames first then message") {
        auto frange = p.get_frames(bin);
        auto f1 = *frange.first++;
        auto f2 = *frange.first;
        CHECK_FRAME(f1).payload("part1");
        CHECK_FRAME(f2).opcode(Opcode::CONTINUE).payload("part2");
        auto mrange = p.get_messages();
        auto m = *mrange.first++;
        CHECK_MESSAGE(m).payload("msg");
        CHECK(mrange.first == mrange.second);
    }

    SECTION("1 frame then message") {
        auto frange = p.get_frames(bin);
        CHECK_FRAME(*frange.first).opcode(Opcode::TEXT).payload("part1");
        CHECK_THROWS_AS(p.get_messages(), Error);
    }
}

TEST("1x2 frame + control in the middle + message") {
    EstablishedServerParser p;
    auto bin = gen_frame().opcode(Opcode::TEXT).mask().payload("fpart1").str() +
               gen_frame().opcode(Opcode::PING).mask().final().str() +
               gen_frame().opcode(Opcode::CONTINUE).mask().final().payload("fpart2").str() +
               gen_message().mask().payload("msg").str();

    auto frange = p.get_frames(bin);

    SECTION("3 frames first then message") {
        auto f1 = *frange.first++;
        auto cl = *frange.first++;
        auto f2 = *frange.first;
        CHECK_FRAME(f1).opcode(Opcode::TEXT).payload("fpart1");
        CHECK_FRAME(cl).opcode(Opcode::PING);
        CHECK_FRAME(f2).opcode(Opcode::CONTINUE).payload("fpart2");
        auto mrange = p.get_messages();
        CHECK_MESSAGE(*mrange.first).payload("msg");
    }

    SECTION("1 frame then control then message") {
        auto f1 = *frange.first++;
        auto cl = *frange.first;
        CHECK_FRAME(f1).opcode(Opcode::TEXT).payload("fpart1");
        CHECK_FRAME(cl).opcode(Opcode::PING);
        CHECK_THROWS_AS(p.get_messages(), Error);
    }
}

TEST("1x2 message + frame") {
    EstablishedServerParser p;
    auto bin1 = gen_message().mask().payload("pingpong").nframes(2).vec();
    auto bin2 = gen_message().mask().payload("trololo").str();

    SECTION("message first then frame") {
        auto mrange = p.get_messages(bin1[0]);
        CHECK(mrange.first == mrange.second); // not yet
        mrange = p.get_messages(bin1[1]);
        CHECK_MESSAGE(*mrange.first).payload("pingpong");
        auto frange = p.get_frames();
        CHECK(frange.first == frange.second); // not yet
        frange = p.get_frames(bin2);
        CHECK_FRAME(*frange.first).payload("trololo");
    }

    SECTION("partial message first then frame") {
        auto mrange = p.get_messages(bin1[0]);
        CHECK(mrange.first == mrange.second); // not yet
        CHECK_THROWS_AS(p.get_frames(bin2), Error); // exception when trying to get frames
    }
}

TEST("1x2 message + control in the middle + frame") {
    EstablishedServerParser p;
    auto bin1 = gen_message().mask().payload("pingpong").nframes(2).vec();
    auto cbin = gen_frame().opcode(Opcode::PONG).mask().final().str();
    auto bin2 = gen_message().mask().payload("trololo").str();

    SECTION("message first then frame") {
        auto mrange = p.get_messages(bin1[0]);
        CHECK(mrange.first == mrange.second); // not yet
        mrange = p.get_messages(cbin);
        CHECK_MESSAGE(*mrange.first).opcode(Opcode::PONG);
        mrange = p.get_messages(bin1[1]);
        CHECK_MESSAGE(*mrange.first).payload("pingpong");
        auto frange = p.get_frames();
        CHECK(frange.first == frange.second); // not yet
        frange = p.get_frames(bin2);
        CHECK_FRAME(*frange.first).payload("trololo");
    }

    SECTION("partial message then control then frame") {
        auto mrange = p.get_messages(bin1[0]);
        CHECK(mrange.first == mrange.second); // not yet
        mrange = p.get_messages(cbin);
        CHECK_MESSAGE(*mrange.first).opcode(Opcode::PONG);
        CHECK_THROWS_AS(p.get_frames(bin1[1]), Error);
    }
}
