#include "../test.h"

#define TEST(name) TEST_CASE("send-message: " name, "[send-message]")

TEST("one frame message") {
    EstablishedServerParser p;
    string payload = "preved"; // must be <= 125
    auto bin = p.message().deflate(false).send(payload);
    CHECK_BINFRAME(bin).final().opcode(Opcode::BINARY).payload(payload).binlen(2 + 6);

    std::vector<string_view> plist = {"pr", "ev", "ed"};
    CHECK((p.message().deflate(false).send(plist.begin(), plist.end()) == bin));
}

TEST("multi frame message") {
    EstablishedServerParser p;

    std::vector<string> vbin;

    SECTION("via it") {
        std::vector<string_view> plist = {"first", "second", "third"};
        vbin = p.message().deflate(false).send_multiframe(plist.begin(), plist.end());
    }
    SECTION("via it-it") {
        std::vector<std::vector<string_view>> plist = {
            {"fir", "st"},
            {"second"},
            {"th", "ir", "d"}
        };
        vbin = p.message().deflate(false).send_multiframe(plist.begin(), plist.end());
    }

    CHECK(vbin.size() == 3);
    CHECK(join(vbin).length() == 22); // (2 header + 5 payload) + (2 header + 6 payload) + (2 header + 5 payload)
    CHECK((vbin[0] == gen_frame().opcode(Opcode::BINARY).payload("first").str()));
    CHECK((vbin[1] == gen_frame().opcode(Opcode::CONTINUE).payload("second").str()));
    CHECK((vbin[2] == gen_frame().final().opcode(Opcode::CONTINUE).payload("third").str()));
}
