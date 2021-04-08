#include "../test.h"

#define TEST(name) TEST_CASE("parse-frames: " name, "[parse-frames]")

TEST("dies until established") {
    CHECK_THROWS_AS(ServerParser().get_frames("asdasd"), Error);
    CHECK_THROWS_AS(ClientParser().get_frames("asdasd"), Error);
}

TEST("basic") {
    EstablishedServerParser p;

    SECTION("small frame") {
        test_frame(p, gen_frame().opcode(Opcode::BINARY).mask().final().payload("hello world"));
    }
    SECTION("medium frame") {
        test_frame(p, gen_frame().opcode(Opcode::BINARY).mask().final().payload(repeat("1", 1024)));
    }
    SECTION("big frame") {
        test_frame(p, gen_frame().opcode(Opcode::TEXT).mask().final().payload(repeat("1", 70000)));
    }
    SECTION("empty frame") {
        test_frame(p, gen_frame().opcode(Opcode::TEXT).mask().final());
    }
}

TEST("bad opcodes") {
    EstablishedServerParser p;
    for (int i = 3; i <= 7; ++i) { DYNAMIC_SECTION(i) {
        test_frame(p, gen_frame().opcode((Opcode)i).mask().final().payload("hello world"), errc::invalid_opcode);
    }}
}

TEST("max frame size") {
    Parser::Config cfg;
    cfg.max_frame_size = 1000;
    EstablishedServerParser p(cfg);
    SECTION("allowed") {
        test_frame(p, gen_frame().opcode(Opcode::TEXT).mask().final().payload(repeat("1", 1000)));
    }
    SECTION("exceeds") {
        test_frame(p, gen_frame().opcode(Opcode::TEXT).mask().final().payload(repeat("1", 1001)), errc::max_frame_size);
    }
}

TEST("ping") {
    EstablishedServerParser p;
    SECTION("empty") {
        test_frame(p, gen_frame().opcode(Opcode::PING).mask().final());
    }
    SECTION("payload") {
        test_frame(p, gen_frame().opcode(Opcode::PING).mask().final().payload("pingdata"));
    }
    SECTION("fragmented") {
        test_frame(p, gen_frame().opcode(Opcode::PING).mask(), errc::control_fragmented);
    }
    SECTION("long") {
        test_frame(p, gen_frame().opcode(Opcode::PING).mask().final().payload(repeat("1", 1000)), errc::control_payload_too_big);
    }
}

TEST("pong") {
    EstablishedServerParser p;
    SECTION("empty") {
        test_frame(p, gen_frame().opcode(Opcode::PONG).mask().final());
    }
    SECTION("payload") {
        test_frame(p, gen_frame().opcode(Opcode::PONG).mask().final().payload("pongdata"));
    }
    SECTION("fragmented") {
        test_frame(p, gen_frame().opcode(Opcode::PONG).mask(), errc::control_fragmented);
    }
    SECTION("long") {
        test_frame(p, gen_frame().opcode(Opcode::PONG).mask().final().payload(repeat("1", 1000)), errc::control_payload_too_big);
    }
}

TEST("close") {
    EstablishedServerParser p;
    SECTION("empty") {
        test_frame(p, gen_frame().opcode(Opcode::CLOSE).mask().final().close_code_check(CloseCode::UNKNOWN));
        auto frames = get_frames(p, gen_frame().opcode(Opcode::TEXT).mask().final().str());
        CHECK(frames.size() == 0); //no more frames available after close
    }
    SECTION("code") {
        test_frame(p, gen_frame().opcode(Opcode::CLOSE).mask().final().close_code(CloseCode::DONE));
    }
    SECTION("message") {
        test_frame(p, gen_frame().opcode(Opcode::CLOSE).mask().final().close_code(CloseCode::AWAY).payload("walk"));
    }
    SECTION("invalid payload") {
        test_frame(p, gen_frame().opcode(Opcode::CLOSE).mask().final().payload("a"), errc::close_frame_invalid_data);
    }
    SECTION("fragmented") {
        test_frame(p, gen_frame().opcode(Opcode::CLOSE).mask(), errc::control_fragmented);
    }
    SECTION("long") {
        test_frame(p, gen_frame().opcode(Opcode::CLOSE).mask().final().close_code(CloseCode::AWAY).payload(repeat("1", 1000)), errc::control_payload_too_big);
    }
    SECTION("invalid close codes") {
        for (auto code : {0, 999, 1004, (int)CloseCode::UNKNOWN, (int)CloseCode::ABNORMALLY, (int)CloseCode::TLS, 1100}) {
            DYNAMIC_SECTION(string("code ") + panda::to_string(code)) {
                test_frame(p, gen_frame().opcode(Opcode::CLOSE).mask().final().close_code(code).payload("a"), errc::close_frame_invalid_data);
            }
        }
    }
    SECTION("custom code") {
        test_frame(p, gen_frame().opcode(Opcode::CLOSE).mask().final().close_code(3000));
    }
}

TEST("2 frames") {
    EstablishedServerParser p;
    auto bin = gen_frame().opcode(Opcode::TEXT).mask().final().payload("jopa1").str() +
               gen_frame().opcode(Opcode::TEXT).mask().final().payload("jopa2").str();
    auto frames = get_frames(p, bin);
    CHECK(frames.size() == 2);
    CHECK_FRAME(frames[0]).final().payload("jopa1");
    CHECK_FRAME(frames[1]).final().payload("jopa2");
}

TEST("3 frames") {
    EstablishedServerParser p;
    auto bin = gen_frame().opcode(Opcode::TEXT).mask().final().payload("jopa1").str() +
               gen_frame().opcode(Opcode::TEXT).mask().final().payload("jopa2").str() +
               gen_frame().opcode(Opcode::TEXT).mask().final().payload("jopa3").str();
    auto frames = get_frames(p, bin);
    CHECK(frames.size() == 3);
    CHECK_FRAME(frames[0]).final().payload("jopa1");
    CHECK_FRAME(frames[1]).final().payload("jopa2");
    CHECK_FRAME(frames[2]).final().payload("jopa3");
}

TEST("2.5 frames + 1.5 frames") {
    EstablishedServerParser p;
    auto tmp = gen_frame().opcode(Opcode::TEXT).mask().final().payload("jopa3").str();
    auto bin = gen_frame().opcode(Opcode::TEXT).mask().final().payload("jopa1").str() +
               gen_frame().opcode(Opcode::TEXT).mask().final().payload("jopa2").str() +
               tmp.substr(0, tmp.length()-1);
    tmp.offset(tmp.length()-1);
    auto frames = get_frames(p, bin);
    CHECK(frames.size() == 2);
    CHECK_FRAME(frames[0]).payload("jopa1");
    CHECK_FRAME(frames[1]).payload("jopa2");
    frames = get_frames(p, tmp + gen_frame().opcode(Opcode::TEXT).mask().final().payload("jopa4").str());
    CHECK(frames.size() == 2);
    CHECK_FRAME(frames[0]).payload("jopa3");
    CHECK_FRAME(frames[1]).payload("jopa4");
}

TEST("initial frame in message with CONTINUE") {
    EstablishedServerParser p;
    test_frame(p, gen_frame().opcode(Opcode::CONTINUE).mask().final().payload("jopa"), errc::initial_continue);
}

TEST("fragment frame in message without CONTINUE") {
    EstablishedServerParser p;
    auto bin = gen_frame().opcode(Opcode::TEXT).mask().payload("p1").str() +
               gen_frame().opcode(Opcode::TEXT).mask().payload("p2").str();
    auto frames = get_frames(p, bin);
    CHECK_FRAME(frames[0]).payload("p1");
    CHECK(frames[1]->error() == ErrorCode(errc::fragment_no_continue));
    bin = gen_frame().opcode(Opcode::BINARY).mask().payload("p1").str() +
          gen_frame().opcode(Opcode::BINARY).mask().final().payload("p2").str();
    frames = get_frames(p, bin);
    CHECK(frames[1]->error() == ErrorCode(errc::fragment_no_continue)); // fin does not matter
}

TEST("mask") {
    EstablishedServerParser sp;
    EstablishedClientParser cp;
    SECTION("unmasked frame in server parser") {
        test_frame(sp, gen_frame().opcode(Opcode::TEXT).final().payload("jopa"), errc::not_masked);
    }
    SECTION("unmasked empty frame in server parser") {
        test_frame(sp, gen_frame().opcode(Opcode::TEXT).final());
    }
    SECTION("masked frame in client parser") {
        test_frame(cp, gen_frame().opcode(Opcode::TEXT).mask().final().payload("jopa"));
    }
    SECTION("unmasked frame in client parser") {
        test_frame(cp, gen_frame().opcode(Opcode::TEXT).final().payload("jopa"));
    }
}
