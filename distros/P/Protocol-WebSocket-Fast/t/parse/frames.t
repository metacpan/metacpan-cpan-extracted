use 5.012;
use warnings;
use lib 't/lib';
use MyTest qw/gen_frame test_frame/;
use Test::More;
use Test::Deep;
use Test::Exception;
use Protocol::WebSocket::Fast;

subtest "server parser" => sub {
    my $p = MyTest::get_established_server();

    dies_ok { Protocol::WebSocket::Fast::ServerParser->new->get_frames('asdasd') } "server parser cant get frames until established";
    dies_ok { Protocol::WebSocket::Fast::ClientParser->new->get_frames('asdasd') } "client parser cant get frames until established";

    subtest 'small frame'  => \&test_frame,  $p, {opcode => OPCODE_BINARY, mask => 1, fin => 1, data => "hello world"};
    subtest 'medium frame' => \&test_frame,  $p, {opcode => OPCODE_BINARY, mask => 1, fin => 1, data => ("1" x 1024)};
    subtest 'big frame'    => \&test_frame,  $p, {opcode => OPCODE_TEXT,   mask => 1, fin => 1, data => ("1" x 70000)};
    subtest 'empty frame'  => \&test_frame,  $p, {opcode => OPCODE_TEXT,   mask => 1, fin => 1};

    subtest "bad opcode $_"   => \&test_frame,  $p, {opcode => $_, mask => 1, fin => 1, data => "hello world"}, Protocol::WebSocket::Fast::Error::invalid_opcode for (3..7);

    subtest 'max frame size' => sub {
        $p->configure({max_frame_size => 1000});
        subtest 'allowed' => \&test_frame,  $p, {opcode => OPCODE_TEXT, mask => 1, fin => 1, data => ("1" x 1000)};
        subtest 'exceeds' => \&test_frame,  $p, {opcode => OPCODE_TEXT, mask => 1, fin => 1, data => ("1" x 1001)}, Protocol::WebSocket::Fast::Error::max_frame_size;
        $p->configure({max_frame_size => 0});
    };

    subtest 'ping' => sub {
        subtest 'empty'      => \&test_frame,  $p, {opcode => OPCODE_PING, mask => 1, fin => 1};
        subtest 'payload'    => \&test_frame,  $p, {opcode => OPCODE_PING, mask => 1, fin => 1, data => "pingdata"};
        subtest 'fragmented' => \&test_frame,  $p, {opcode => OPCODE_PING, mask => 1, fin => 0}, Protocol::WebSocket::Fast::Error::control_fragmented;
        subtest 'long'       => \&test_frame,  $p, {opcode => OPCODE_PING, mask => 1, fin => 1, data => ("1" x 1000)}, Protocol::WebSocket::Fast::Error::control_payload_too_big;
    };

    subtest 'pong' => sub {
        subtest 'empty'      => \&test_frame,  $p, {opcode => OPCODE_PONG, mask => 1, fin => 1};
        subtest 'payload'    => \&test_frame,  $p, {opcode => OPCODE_PONG, mask => 1, fin => 1, data => "pongdata"};
        subtest 'fragmented' => \&test_frame,  $p, {opcode => OPCODE_PONG, mask => 1, fin => 0}, Protocol::WebSocket::Fast::Error::control_fragmented;
        subtest 'long'       => \&test_frame,  $p, {opcode => OPCODE_PONG, mask => 1, fin => 1, data => ("1" x 1000)}, Protocol::WebSocket::Fast::Error::control_payload_too_big;
    };

    subtest 'close' => sub {
        subtest 'empty' => \&test_frame,  $p, {opcode => OPCODE_CLOSE, mask => 1, fin => 1, close_code => all(CLOSE_UNKNOWN)};

        my ($frame) = $p->get_frames(gen_frame({opcode => OPCODE_TEXT, mask => 1, fin => 1}));
        ok(!$frame, "no more frames available after close");
        MyTest::reset($p);

        subtest 'code' => \&test_frame,  $p, {opcode => OPCODE_CLOSE, mask => 1, fin => 1, close_code => CLOSE_DONE};
        MyTest::reset($p);
        subtest 'message' => \&test_frame,  $p, {opcode => OPCODE_CLOSE, mask => 1, fin => 1, close_code => CLOSE_AWAY, data => "walk"};
        MyTest::reset($p);
        subtest 'invalid payload' => \&test_frame,  $p, {opcode => OPCODE_CLOSE, mask => 1, fin => 1, data => "a"}, Protocol::WebSocket::Fast::Error::close_frame_invalid_data;
        MyTest::reset($p);
        subtest 'fragmented' => \&test_frame,  $p, {opcode => OPCODE_CLOSE, mask => 1, fin => 0}, Protocol::WebSocket::Fast::Error::control_fragmented;
        MyTest::reset($p);
        subtest 'long' => \&test_frame,  $p, {opcode => OPCODE_CLOSE, mask => 1, fin => 1, close_code => CLOSE_AWAY, data => ("1" x 1000)}, Protocol::WebSocket::Fast::Error::control_payload_too_big;
        MyTest::reset($p);
        foreach my $code (0, 999, 1004, CLOSE_UNKNOWN, CLOSE_ABNORMALLY, CLOSE_TLS, 1100) {
            subtest "invalid close $code" => \&test_frame,  $p, {opcode => OPCODE_CLOSE, mask => 1, fin => 1, close_code => $code, data => "a"}, Protocol::WebSocket::Fast::Error::close_frame_invalid_data;
            MyTest::reset($p);
        }
        subtest 'custom code' => \&test_frame,  $p, {opcode => OPCODE_CLOSE, mask => 1, fin => 1, close_code => 3000};
        MyTest::reset($p);
    };

    subtest '2 frames via it->next' => sub {
        my $bin = gen_frame({opcode => OPCODE_TEXT, mask => 1, fin => 1, data => "jopa1"}).
                  gen_frame({opcode => OPCODE_TEXT, mask => 1, fin => 1, data => "jopa2"});
        my $it = $p->get_frames($bin);
        my ($first, $second) = ($it->next, $it->next);
        ok($first && $second && !$it->next, "2 frames returned");
        cmp_deeply([$first->error, $second->error], [undef, undef], "no errors");
        cmp_deeply([$first, $second], [methods(final => 1, payload => "jopa1"), methods(final => 1, payload => "jopa2")], "data ok");
    };

    subtest '3 frames via list context' => sub {
        my $bin = gen_frame({opcode => OPCODE_TEXT, mask => 1, fin => 1, data => "jopa1"}).
                  gen_frame({opcode => OPCODE_TEXT, mask => 1, fin => 1, data => "jopa2"}).
                  gen_frame({opcode => OPCODE_TEXT, mask => 1, fin => 1, data => "jopa3"});
        my @frames = $p->get_frames($bin);
        is(scalar(@frames), 3, "3 frames returned");
        cmp_deeply([map {$_->error} @frames], [undef, undef, undef], "no errors");
        cmp_deeply(\@frames, [methods(payload => "jopa1"), methods(payload => "jopa2"), methods(payload => "jopa3")], "data ok");
    };

    subtest '2.5 frames + 1.5 frames' => sub {
        my $tmp = gen_frame({opcode => OPCODE_TEXT, mask => 1, fin => 1, data => "jopa3"});
        my $bin = gen_frame({opcode => OPCODE_TEXT, mask => 1, fin => 1, data => "jopa1"}).
                  gen_frame({opcode => OPCODE_TEXT, mask => 1, fin => 1, data => "jopa2"}).
                  substr($tmp, 0, length($tmp)-1, '');
        my @frames = $p->get_frames($bin);
        is(scalar(@frames), 2, "2 returned");
        cmp_deeply(\@frames, [methods(payload => "jopa1"), methods(payload => "jopa2")], "data ok");
        $bin = $tmp.gen_frame({opcode => OPCODE_TEXT, mask => 1, fin => 1, data => "jopa4"});
        @frames = $p->get_frames($bin);
        is(scalar(@frames), 2, "2 more returned");
        cmp_deeply(\@frames, [methods(payload => "jopa3"), methods(payload => "jopa4")], "2 more data ok");
    };

    subtest 'initial frame in message with CONTINUE' => \&test_frame,  $p, {opcode => OPCODE_CONTINUE, mask => 1, fin => 1, data => 'jopa'}, Protocol::WebSocket::Fast::Error::initial_continue;

    subtest 'fragment frame in message without CONTINUE' => sub {
        my $bin = gen_frame({opcode => OPCODE_TEXT, mask => 1, fin => 0, data => 'p1'}).
                  gen_frame({opcode => OPCODE_TEXT, mask => 1, fin => 0, data => 'p2'});
        my ($first, $second) = $p->get_frames($bin);
        is($first->error, undef, "initial frame ok");
        is($first->payload, 'p1', "initial data ok");
        is($second->error, Protocol::WebSocket::Fast::Error::fragment_no_continue, "fragment frame error ok");
        $bin = gen_frame({opcode => OPCODE_BINARY, mask => 1, fin => 0, data => 'p1'}).
               gen_frame({opcode => OPCODE_BINARY, mask => 1, fin => 1, data => 'p2'});
        ($first, $second) = $p->get_frames($bin);
        is($second->error, Protocol::WebSocket::Fast::Error::fragment_no_continue, "fin does not matter");
    };

    subtest 'unmasked frame in server parser'       => \&test_frame,  $p, {opcode => OPCODE_TEXT, mask => 0, fin => 1, data => "jopa"}, Protocol::WebSocket::Fast::Error::not_masked;
    subtest 'unmasked empty frame in server parser' => \&test_frame,  $p, {opcode => OPCODE_TEXT, mask => 0, fin => 1};
};

subtest "client parser" => sub {
    my $p = MyTest::get_established_client();
    subtest 'masked frame in client parser'   => \&test_frame, $p, {opcode => OPCODE_TEXT, mask => 1, fin => 1, data => "jopa"};
    subtest 'unmasked frame in client parser' => \&test_frame, $p, {opcode => OPCODE_TEXT, mask => 0, fin => 1, data => "jopa"};
};

done_testing();

