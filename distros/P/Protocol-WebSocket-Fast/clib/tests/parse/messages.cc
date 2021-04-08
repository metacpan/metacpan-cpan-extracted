#include "../test.h"

#define TEST(name) TEST_CASE("parse-messages: " name, "[parse-messages]")

TEST("cant get messages until established") {
    ServerParser p;
    CHECK_THROWS_AS(p.get_messages("asdf"), Error);
}

TEST("basic") {
    EstablishedServerParser p;
    SECTION("single frame") {
        test_message(p, gen_frame().mask().payload("hello world").nframes(1));
    }
    SECTION("2 frames") {
        test_message(p, gen_frame().mask().payload("hello world").nframes(2));
    }
    SECTION("many frames") {
        test_message(p, gen_frame().mask().payload(repeat("suchka hey", 100)).nframes(49));
    }
    SECTION("empty") {
        test_message(p, gen_frame().mask());
    }
}

TEST("ping") {
    EstablishedServerParser p;
    SECTION("empty") {
        test_message(p, gen_frame().opcode(Opcode::PING).mask().final());
    }
    SECTION("payload") {
        test_message(p, gen_frame().opcode(Opcode::PING).mask().final().payload("pingdata"));
    }
    SECTION("fragmented") {
        test_message(p, gen_frame().opcode(Opcode::PING).mask(), errc::control_fragmented);
    }
    SECTION("long") {
        test_message(p, gen_frame().opcode(Opcode::PING).mask().final().payload(repeat("1", 1000)), errc::control_payload_too_big);
    }
}

TEST("pong") {
    EstablishedServerParser p;
    SECTION("empty") {
        test_message(p, gen_frame().opcode(Opcode::PONG).mask().final());
    }
    SECTION("payload") {
        test_message(p, gen_frame().opcode(Opcode::PONG).mask().final().payload("pongdata"));
    }
    SECTION("fragmented") {
        test_message(p, gen_frame().opcode(Opcode::PONG).mask(), errc::control_fragmented);
    }
    SECTION("long") {
        test_message(p, gen_frame().opcode(Opcode::PONG).mask().final().payload(repeat("1", 1000)), errc::control_payload_too_big);
    }
}

TEST("close") {
    EstablishedServerParser p;
    SECTION("empty") {
        test_message(p, gen_frame().opcode(Opcode::CLOSE).mask().final().close_code_check(CloseCode::UNKNOWN));
        auto messages = get_messages(p, gen_frame().opcode(Opcode::TEXT).mask().final());
        CHECK(messages.size() == 0); // no more messages available after close
    }
    SECTION("code") {
        test_message(p, gen_frame().opcode(Opcode::CLOSE).mask().final().close_code(CloseCode::DONE));
    }
    SECTION("message") {
        test_message(p, gen_frame().opcode(Opcode::CLOSE).mask().final().close_code(CloseCode::AWAY).payload("walk"));
    }
    SECTION("invalid payload") {
        test_message(p, gen_frame().opcode(Opcode::CLOSE).mask().final().payload("a"), errc::close_frame_invalid_data);
    }
    SECTION("fragmented") {
        test_message(p, gen_frame().opcode(Opcode::CLOSE).mask(), errc::control_fragmented);
    }
    SECTION("long") {
        test_message(p, gen_frame().opcode(Opcode::CLOSE).mask().final().close_code(CloseCode::AWAY).payload(repeat("1", 1000)), errc::control_payload_too_big);
    }
}

TEST("max message size") {
    Parser::Config cfg;
    cfg.max_frame_size = 2000;
    cfg.max_message_size = 1000;
    EstablishedServerParser p(cfg);
    SECTION("allowed") {
        test_message(p, gen_frame().opcode(Opcode::TEXT).mask().final().payload(repeat("1", 1000)));
    }
    SECTION("exceeds") {
        test_message(p, gen_frame().opcode(Opcode::TEXT).mask().final().payload(repeat("1", 1001)), errc::max_message_size);
    }
}

TEST("2 messages") {
    EstablishedServerParser p;
    auto bin = gen_message().mask().payload("jopa1").nframes(1).str() +
               gen_message().mask().payload("jopa2").nframes(2).str();
    auto messages = get_messages(p, bin);
    CHECK(messages.size() == 2);
    CHECK_MESSAGE(messages[0]).nframes(1).payload("jopa1");
    CHECK_MESSAGE(messages[1]).nframes(2).payload("jopa2");
}

TEST("3 messages") {
    EstablishedServerParser p;
    auto bin = gen_message().mask().payload("jopa1").nframes(1).str() +
               gen_message().mask().payload("jopa2").nframes(2).str() +
               gen_message().mask().payload("jopa3").nframes(3).str();
    auto messages = get_messages(p, bin);
    CHECK(messages.size() == 3);
    CHECK_MESSAGE(messages[0]).nframes(1).payload("jopa1");
    CHECK_MESSAGE(messages[1]).nframes(2).payload("jopa2");
    CHECK_MESSAGE(messages[2]).nframes(3).payload("jopa3");
}

TEST("control frame in the middle of multi-frame message") {
    EstablishedServerParser p;
    auto vbin = gen_message().mask().payload("you are kewl").nframes(4).vec();
    vbin.insert(vbin.begin()+2, gen_frame().opcode(Opcode::PING).mask().final().str());
    auto messages = get_messages(p, join(vbin));
    CHECK(messages.size() == 2);
    CHECK_MESSAGE(messages[0]).nframes(1).opcode(Opcode::PING);
    CHECK_MESSAGE(messages[1]).nframes(4).payload("you are kewl");
}

TEST("the same one-by-one frame") {
    EstablishedServerParser p;
    auto vbin = gen_message().mask().payload("you are bad").nframes(4).vec();
    vbin.insert(vbin.begin()+2, gen_frame().opcode(Opcode::PONG).mask().final().str());
    auto messages = get_messages(p, vbin[0]);
    CHECK(messages.size() == 0); // not yet
    messages = get_messages(p, vbin[1]);
    CHECK(messages.size() == 0); // and not yet
    messages = get_messages(p, vbin[2]);
    CHECK(messages.size() == 1);
    CHECK_MESSAGE(messages[0]).nframes(1).opcode(Opcode::PONG); // control message arrived
    messages = get_messages(p, vbin[3]);
    CHECK(messages.size() == 0); // still not yet
    messages = get_messages(p, vbin[4]);
    CHECK(messages.size() == 1);
    CHECK_MESSAGE(messages[0]).nframes(4).payload("you are bad");
}

TEST("2.5 messages + 1.5 messages + control message") {
    EstablishedServerParser p;
    auto first  = gen_message().mask().payload("first message").nframes(1).vec();
    auto second = gen_message().mask().payload("second message").nframes(2).vec();
    auto third  = gen_message().mask().payload("third message").nframes(3).vec();
    auto fourth = gen_message().mask().payload("fourth message").nframes(4).vec();
    auto stolen = third[2].substr(third[2].length() - 1);
    third[2].pop_back();
    auto pong   = gen_frame().opcode(Opcode::PONG).mask().final().str();
    auto messages = get_messages(p, join(first) + join(second) + join(third));
    CHECK(messages.size() == 2);
    CHECK_MESSAGE(messages[0]).nframes(1);
    CHECK_MESSAGE(messages[1]).nframes(2);
    messages = get_messages(p, stolen + fourth[0] + fourth[1] + fourth[2] + pong + fourth[3]);
    CHECK(messages.size() == 3);
    CHECK_MESSAGE(messages[0]).nframes(3).payload("third message");
    CHECK_MESSAGE(messages[1]).opcode(Opcode::PONG); // pong is between 3rd and 4th
    CHECK_MESSAGE(messages[2]).nframes(4).payload("fourth message");
}

TEST("first frame in message with CONTINUE") {
    EstablishedServerParser p;
    test_message(p, gen_frame().opcode(Opcode::CONTINUE).mask().final().payload("jopa"), errc::initial_continue);
}

TEST("fragment frame in message without CONTINUE") {
    EstablishedServerParser p;
    auto bin = gen_frame().opcode(Opcode::TEXT).mask().payload("p1").str() +
               gen_frame().opcode(Opcode::TEXT).mask().final().payload("p2").str();
    auto messages = get_messages(p, bin);
    CHECK(messages.size() == 1);
    CHECK(messages[0]->error() == ErrorCode(errc::fragment_no_continue));
    bin = gen_frame().opcode(Opcode::BINARY).mask().payload("p1").str() +
          gen_frame().opcode(Opcode::BINARY).mask().payload("p2").str();
    messages = get_messages(p, bin);
    CHECK(messages.size() == 1);
    CHECK(messages[0]->error() == ErrorCode(errc::fragment_no_continue)); // uncompleted does not matter
}

TEST("mask") {
    EstablishedServerParser sp;
    EstablishedClientParser cp;
    SECTION("message with unmasked frame in server parser") {
        auto message = test_message(sp, gen_message().opcode(Opcode::TEXT).payload("jopa noviy god").nframes(2), errc::not_masked);
        CHECK(message->frame_count() == 0); // error caught on first frame and rest is dropped, error frame is not counted
    }
    SECTION("message with masked frame in client parser") {
        test_message(cp, gen_frame().mask().payload("jopa"));
    }
    SECTION("message with unmasked frame in client parser") {
        test_message(cp, gen_frame().payload("jopa"));
    }
}
