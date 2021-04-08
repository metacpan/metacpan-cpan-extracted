#include "../test.h"

#define TEST(name) TEST_CASE("parse-utf8: " name, "[parse-utf8]")

static string ascii        = "ok";
static string valid_utf8   = "жопа";
static string invalid_utf8 = "\xc0\xaf\xc0\xaf\xc0\xaf\xc0\xaf";

TEST("by default do not check utf-8") {
    EstablishedClientParser p;
    auto bin = gen_frame().opcode(Opcode::TEXT).payload(invalid_utf8).final().str();
    auto f = get_frame(p, bin);
    CHECK_FRAME(f).payload(invalid_utf8);
}

TEST("check in payload") {
    Parser::Config cfg;
    cfg.check_utf8 = true;
    EstablishedClientParser p(cfg);

    SECTION("ascii") {
        auto bin = gen_frame().opcode(Opcode::TEXT).payload(ascii).final().str();
        auto f = get_frame(p, bin);
        CHECK_FRAME(f).payload(ascii);
    }
    SECTION("valid utf") {
        SECTION("single frame") {
            auto bin = gen_frame().opcode(Opcode::TEXT).payload(valid_utf8).final().str();
            auto f = get_frame(p, bin);
            CHECK_FRAME(f).payload(valid_utf8);
        }
        SECTION("nframes") {
            auto bin = gen_message().opcode(Opcode::TEXT).payload(valid_utf8).nframes(valid_utf8.length()).str();
            auto m = get_message(p, bin);
            CHECK_MESSAGE(m).payload(valid_utf8);
        }
    }
    SECTION("invalid utf") {
        auto bin = gen_frame().opcode(Opcode::TEXT).payload(invalid_utf8).final().str();
        auto f = get_frame(p, bin);
        CHECK(f->error() == ErrorCode(errc::invalid_utf8));
        CHECK(p.suggested_close_code() == CloseCode::INVALID_TEXT);
    }
}

TEST("check in close message") {
    Parser::Config cfg;
    cfg.check_utf8 = true;
    EstablishedClientParser p(cfg);

    SECTION("ascii") {
        auto bin = gen_frame().opcode(Opcode::CLOSE).close_code(CloseCode::DONE).payload(ascii).final().str();
        auto f = get_frame(p, bin);
        CHECK_FRAME(f).close_message(ascii);
    }
    SECTION("valid utf") {
        auto bin = gen_frame().opcode(Opcode::CLOSE).close_code(CloseCode::DONE).payload(valid_utf8).final().str();
        auto f = get_frame(p, bin);
        CHECK_FRAME(f).close_message(valid_utf8);
    }
    SECTION("invalid utf") {
        auto bin = gen_frame().opcode(Opcode::CLOSE).close_code(CloseCode::DONE).payload(invalid_utf8).final().str();
        auto f = get_frame(p, bin);
        CHECK(f->error() == ErrorCode(errc::invalid_utf8));
    }
}
