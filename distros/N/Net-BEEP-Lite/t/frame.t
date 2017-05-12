# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 32;
#use Test::More qw(no_plan);

BEGIN { use_ok('Net::BEEP::Lite::Frame') };

#########################

# Testing Net::BEEP::Lite::Frame

# the constructor:
my $frame = Net::BEEP::Lite::Frame->new;
ok(defined $frame, 'constructor works');
isa_ok($frame, 'Net::BEEP::Lite::Frame');

$frame = Net::BEEP::Lite::Frame->new(Type    => 'MSG',
				   Msgno   => 100,
				   More    => '*',
				   Seqno   => 10023,
				   Channel => 1);
ok(defined $frame, 'constructor with args works');
isa_ok($frame, 'Net::BEEP::Lite::Frame');
is($frame->type(), 'MSG', 'frame->type()');
is($frame->msgno(), 100, 'frame->msgno()');
is($frame->size(), 0, 'frame->size()');
is($frame->more(), '*', 'frame->more()');
is($frame->seqno(), 10023, 'frame->seqno()');
is($frame->channel_number(), 1, 'frame->channel_number()');
ok(not ($frame->completes()), 'frame->completes() is false');

# the to_string stuff.
my $header_string = $frame->header_to_string();
is($header_string, "MSG 1 100 * 10023 0\r\n", 'frame->header_to_string()');

# a SEQ frame.
$frame = Net::BEEP::Lite::Frame->new(Type    => 'SEQ',
				   Channel => 1,
				   Ackno   => 10023,
				   Window  => 8192);
$header_string = $frame->header_to_string();
is($header_string, "SEQ 1 10023 8192\r\n",
   'frame->header_to_string() for SEQ');
my $frame_string = $frame->to_string();
is($frame_string, "SEQ 1 10023 8192\r\n", 'frame->to_string() for SEQ');
$frame->set_payload("Stupid SEQ payload!");
# SEQ payloads should be ignored!
is($frame_string, "SEQ 1 10023 8192\r\n",
   'frame->to_string() for SEQ w/payload');

# Test a full ANS frame.
my $ans_payload = 'Answer Payload!';
$frame = Net::BEEP::Lite::Frame->new(Type    => 'ANS',
				   Msgno   => 100,
				   More    => '.',
				   Seqno   => 10023,
				   Channel => 1,
				   Ansno   => 4,
				   Payload => $ans_payload);
is($frame->size(), length($ans_payload), 'frame->size() w/ payload');
$frame_string = $frame->to_string();
my $expected_result = <<EOD;
ANS 1 100 . 10023 15 4\r
Answer Payload!END\r
EOD
is($frame_string, $expected_result, 'frame->to_string() w/ payload');

# The the other main form of the constructor:
my $example_header = "NUL 2 7 . 289 0\r\n";
$frame = new Net::BEEP::Lite::Frame(Header => $example_header);
is($frame->type(), 'NUL', 'frame->type() from header');
is($frame->size(), 0, 'frame->size() from header');
is($frame->channel_number(), 2, 'frame->channel_number() from header');
is($frame->msgno(), 7, 'frame->msgno() from header');
is($frame->more(), '.', 'frame->more() from header');
is($frame->seqno(), 289, 'frame-seqno() from header');
ok($frame->completes(), "frame->completes() is true");

my $example_header = "RPY 2 7 . 289 77";
$frame = new Net::BEEP::Lite::Frame(Header => $example_header);
is($frame->type(), 'RPY', 'frame->type() from trimmed header');
is($frame->channel_number(), 2, 'frame->channel_number() from trimmed header');
is($frame->msgno(), 7, 'frame->msgno() from trimmed header');
is($frame->more(), '.', 'frame->more() from trimmed header');
is($frame->seqno(), 289, 'frame->seqno() from trimmed header');
is($frame->size(), 77, 'frame->size() from trimmed header');

my $rpy_payload = 'reply payload.  blah blah blah.\n';
$frame->set_payload($rpy_payload);

is($frame->size(), length $rpy_payload, 'frame->size() after payload');
