use 5.012;
use warnings;
use lib 't/lib';
use MyTest qw/gen_frame/;
use Test::More;
use Protocol::WebSocket::Fast;

subtest 'RSV must be 0, when no extension defining RSV meaning has been negotiated' => sub {
    my $bin = MyTest::gen_frame({opcode => OPCODE_TEXT, mask => 1, fin => 1, data => "jopa1", rsv1 => 1});
    subtest 'via frames' => sub {
        my $p = MyTest::get_established_server();
        my ($frame) = $p->get_frames($bin);
        is $frame->error, Protocol::WebSocket::Fast::Error::unexpected_rsv;
    };
    subtest 'via messages' => sub {
        my $p = MyTest::get_established_server();
        my ($msg) = $p->get_messages($bin);
        is $msg->error, Protocol::WebSocket::Fast::Error::unexpected_rsv;
    };
};

done_testing();
