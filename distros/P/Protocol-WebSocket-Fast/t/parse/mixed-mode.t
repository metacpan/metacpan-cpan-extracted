use 5.012;
use warnings;
use lib 't/lib';
use MyTest qw/gen_frame gen_message/;
use Test::More;
use Test::Deep;
use Test::Catch;
use Protocol::WebSocket::Fast;

catch_run("[parse-mixed-mode]");

my $p = MyTest::get_established_server();

subtest 'frame + message' => sub {
    my $bin = gen_message({mask => 1, data => "iframe"}).
              gen_message({mask => 1, data => "imessage"});
    my $fit = $p->get_frames($bin);
    my $frame = $fit->next;
    cmp_deeply($frame, methods(payload => "iframe"), "frame received");
    my $mit = $fit->get_messages;
    is($fit->next, undef, "previous iterator invalidated");
    my $message = $mit->next;
    cmp_deeply($message, methods(payload => "imessage", frame_count => 1), "message received");
    is($mit->next, undef, "nothing more");
};

subtest 'message + frame' => sub {
    my $bin = gen_message({mask => 1, data => "imessage2"}).
              gen_message({mask => 1, data => "iframe2"});
    my $mit = $p->get_messages($bin);
    my $message = $mit->next;
    cmp_deeply($message, methods(payload => "imessage2", frame_count => 1), "message received");
    my $fit = $mit->get_frames;
    is($mit->next, undef, "previous iterator invalidated");
    my $frame = $fit->next;
    cmp_deeply($frame, methods(payload => "iframe2"), "frame received");
    is($fit->next, undef, "nothing more");
};

subtest '1x2 frame + message' => sub {
    my $bin = gen_message({mask => 1, data => "part1part2", nframes => 2}).
              gen_message({mask => 1, data => "msg"});
    
    subtest '2 frames first then message' => sub {
        my $fit = $p->get_frames($bin);
        my $f1 = $fit->next;
        my $f2 = $fit->next;
        cmp_deeply($f1, methods(payload => "part1"), "frame1 ok");
        cmp_deeply($f2, methods(opcode => OPCODE_CONTINUE, payload => "part2"), "frame2 ok");
        my $mit = $fit->get_messages;
        my $m = $mit->next;
        cmp_deeply($m, methods(payload => "msg"), "message ok");
    };
    
    subtest '1 frame then message' => sub {
        my $fit = $p->get_frames($bin);
        my $f1 = $fit->next;
        cmp_deeply($f1, methods(opcode => OPCODE_TEXT, payload => "part1"), "frame ok");
        ok(!eval {$fit->get_messages}, "exception when trying to get messages");
        MyTest::reset($p);
    };
};

subtest '1x2 frame + control in the middle + message' => sub {
    my $bin = gen_frame({opcode => OPCODE_TEXT,     mask => 1, fin => 0, data => "fpart1"}).
              gen_frame({opcode => OPCODE_PING,     mask => 1, fin => 1}).
              gen_frame({opcode => OPCODE_CONTINUE, mask => 1, fin => 1, data => "fpart2"}).
              gen_message({mask => 1, data => "msg"});
    
    subtest '3 frames first then message' => sub {
        my $fit = $p->get_frames($bin);
        my $f1 = $fit->next;
        my $cl = $fit->next;
        my $f2 = $fit->next;
        ok($f1 && $f2 && $cl, "3 returned");
        cmp_deeply($f1, methods(opcode => OPCODE_TEXT, payload => "fpart1"), "frame1 ok");
        cmp_deeply($cl, methods(opcode => OPCODE_PING), "control ok");
        cmp_deeply($f2, methods(opcode => OPCODE_CONTINUE, payload => "fpart2"), "frame2 ok");
        my $mit = $fit->get_messages;
        my $m = $mit->next;
        cmp_deeply($m, methods(payload => "msg"), "message ok");
    };
    
    subtest '1 frame then control then message' => sub {
        my $fit = $p->get_frames($bin);
        my $f1 = $fit->next;
        my $cl = $fit->next;
        cmp_deeply($f1, methods(opcode => OPCODE_TEXT, payload => "fpart1"), "frame ok");
        cmp_deeply($cl, methods(opcode => OPCODE_PING), "control ok");
        ok(!eval {$fit->get_messages}, "exception when trying to get messages");
        MyTest::reset($p);
    };
};

subtest '1x2 message + frame' => sub {
    my ($m1bin1, $m1bin2) = gen_message({mask => 1, data => "pingpong", nframes => 2});
    my $m2bin = gen_message({mask => 1, data => "trololo"});
    
    subtest 'message first then frame' => sub {
        my $mit = $p->get_messages($m1bin1);
        is($mit, undef, "not yet");
        $mit = $p->get_messages($m1bin2);
        my $m = $mit->next;
        cmp_deeply($m, methods(payload => "pingpong"), "message ok");
        my $fit = $mit->get_frames;
        is($fit, undef, "not yet");
        $fit = $p->get_frames($m2bin);
        cmp_deeply($fit->next, methods(payload => "trololo"), "frame ok");
    };
    
    subtest 'partial message first then frame' => sub {
        my $mit = $p->get_messages($m1bin1);
        is($mit, undef, "not yet");
        ok(!eval { $p->get_frames($m1bin2) }, "exception when trying to get frames");
        MyTest::reset($p);
    };
};

subtest '1x2 message + control in the middle + frame' => sub {
    my ($m1bin1, $m1bin2) = gen_message({mask => 1, data => "pingpong", nframes => 2});
    my $cbin  = gen_frame({opcode => OPCODE_PONG, mask => 1, fin => 1});
    my $m2bin = gen_message({mask => 1, data => "trololo"});
    
    subtest 'message first then frame' => sub {
        my $mit = $p->get_messages($m1bin1);
        is($mit, undef, "not yet");
        $mit = $p->get_messages($cbin);
        my $m = $mit->next;
        cmp_deeply($m, methods(opcode => OPCODE_PONG), "control ok");
        $mit = $p->get_messages($m1bin2);
        $m = $mit->next;
        cmp_deeply($m, methods(payload => "pingpong"), "message ok");
        my $fit = $mit->get_frames;
        is($fit, undef, "not yet");
        $fit = $p->get_frames($m2bin);
        cmp_deeply($fit->next, methods(payload => "trololo"), "frame ok");
    };
    
    subtest 'partial message then control then frame' => sub {
        my $mit = $p->get_messages($m1bin1);
        is($mit, undef, "not yet");
        $mit = $p->get_messages($cbin);
        my $m = $mit->next;
        cmp_deeply($m, methods(opcode => OPCODE_PONG), "control ok");
        ok(!eval { $p->get_frames($m1bin2) }, "exception when trying to get frames");
        MyTest::reset($p);
    };
};

done_testing();