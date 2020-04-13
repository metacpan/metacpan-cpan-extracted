use 5.012;
use warnings;
use lib 't/lib';
use MyTest qw/gen_frame gen_message/;
use Test::More;
use Protocol::WebSocket::Fast;

my $ascii        = "ok";
my $valid_utf8   = "жопа";
my $invalid_utf8 = "\xc0\xaf\xc0\xaf\xc0\xaf\xc0\xaf";

subtest 'by default do not check utf-8' => sub {
    my $p = MyTest::get_established_client();
    my $bin = gen_frame({opcode => OPCODE_TEXT, data => $invalid_utf8, fin => 1});
    my ($f) = $p->get_frames($bin);
    is $f->error, undef;
};

subtest 'check in payload' => sub {
    subtest 'ascii' => sub {
        my $p = MyTest::get_established_client({check_utf8 => 1});
        my $bin = gen_frame({opcode => OPCODE_TEXT, data => $ascii, fin => 1});
        my ($f) = $p->get_frames($bin);
        is $f->error, undef;
    };
    subtest 'valid utf' => sub {
        subtest 'single frame' => sub {
            my $p = MyTest::get_established_client({check_utf8 => 1});
            my $bin = gen_frame({opcode => OPCODE_TEXT, data => $valid_utf8, fin => 1});
            my ($f) = $p->get_frames($bin);
            is $f->error, undef;
        };
        subtest 'nframes' => sub {
            my $p = MyTest::get_established_client({check_utf8 => 1});
            my $bin = gen_message({opcode => OPCODE_TEXT, data => $valid_utf8, nframes => length($valid_utf8)});
            my ($m) = $p->get_messages($bin);
            is $m->error, undef;
        };
    };
    subtest 'invalid utf' => sub {
        my $p = MyTest::get_established_client({check_utf8 => 1});
        my $bin = gen_frame({opcode => OPCODE_TEXT, data => $invalid_utf8, fin => 1});
        my ($f) = $p->get_frames($bin);
        is $f->error, Protocol::WebSocket::Fast::Error::invalid_utf8;
        is $p->suggested_close_code, CLOSE_INVALID_TEXT;
    };
};

subtest 'check in close message' => sub {
    subtest 'ascii' => sub {
        my $p = MyTest::get_established_client({check_utf8 => 1});
        my $bin = gen_frame({opcode => OPCODE_CLOSE, close_code => CLOSE_DONE, data => $ascii, fin => 1});
        my ($f) = $p->get_frames($bin);
        is $f->error, undef;
        is $f->close_message, $ascii;
    };
    subtest 'valid utf' => sub {
        my $p = MyTest::get_established_client({check_utf8 => 1});
        my $bin = gen_frame({opcode => OPCODE_CLOSE, close_code => CLOSE_DONE, data => $valid_utf8, fin => 1});
        my ($f) = $p->get_frames($bin);
        is $f->error, undef;
        is $f->close_message, $valid_utf8;
    };
    subtest 'invalid utf' => sub {
        my $p = MyTest::get_established_client({check_utf8 => 1});
        my $bin = gen_frame({opcode => OPCODE_CLOSE, close_code => CLOSE_DONE, data => $invalid_utf8, fin => 1});
        my ($f) = $p->get_frames($bin);
        is $f->error, Protocol::WebSocket::Fast::Error::invalid_utf8;
    };
};

done_testing();
