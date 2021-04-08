#include "../test.h"

#define TEST(name) TEST_CASE("parse-rsv: " name, "[parse-rsv]")

TEST("RSV must be 0, when no extension defining RSV meaning has been negotiated") {
    EstablishedServerParser p;
    auto bin = gen_frame().opcode(Opcode::TEXT).mask().final().payload("jopa1").rsv1().str();
    SECTION("via frames") {
        auto frame = get_frame(p, bin);
        CHECK(frame->error() == ErrorCode(errc::unexpected_rsv));
    }
    SECTION("via messages") {
        auto msg = get_message(p, bin);
        CHECK(msg->error() == ErrorCode(errc::unexpected_rsv));
    }
}
