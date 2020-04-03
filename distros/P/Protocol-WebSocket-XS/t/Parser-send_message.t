use 5.012;
use warnings;
use lib 't'; use MyTest;

*gen_frame = \&MyTest::gen_frame;

my $p = MyTest::get_established_server();

subtest 'one frame message' => sub {
    my $payload = "preved"; # must be <= 125
    my $bin = $p->send_message(deflate => 0, payload => $payload);
    is(length($bin), 8, "frame length ok"); # 2 header + 6 payload
    is_bin($bin, gen_frame({mask => 0, fin => 1, opcode => OPCODE_BINARY, data => $payload}), "frame ok");
    is_bin($p->send_message(deflate => 0, payload => [qw/pr ev ed/]), $bin, "it mode ok");
};

subtest 'multi frame message' => sub {
    my $bin = $p->send_message_multiframe(deflate => 0, payload => [qw/first second third/]);
    is(length($bin), 22, "message length ok"); # (2 header + 5 payload) + (2 header + 6 payload) + (2 header + 5 payload)
    is_bin($bin, gen_frame({mask => 0, fin => 0, opcode => OPCODE_BINARY, data => "first"}).
                 gen_frame({mask => 0, fin => 0, opcode => OPCODE_CONTINUE, data => "second"}).
                 gen_frame({mask => 0, fin => 1, opcode => OPCODE_CONTINUE, data => "third"}),
                 "message ok");
};

done_testing();
