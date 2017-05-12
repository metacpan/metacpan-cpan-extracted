# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 2.t'

#########################

use Test::More tests => 36;
#use Test::More qw(no_plan);

BEGIN { use_ok('Net::BEEP::Lite::Message'); };

#########################

# Testing Net::BEEP::Lite::Message

# the constructor:
my $msg = Net::BEEP::Lite::Message->new;
ok(defined $msg, 'constructor works');
isa_ok($msg, 'Net::BEEP::Lite::Message');

# create a message from scratch.
my $payload = "some message payload!\n";
$msg = new Net::BEEP::Lite::Message(Type 	  => 'MSG',
				  Channel => 1,
				  Payload => $payload);

is($msg->type(), 'MSG', 'msg->type()');
is($msg->size(), length $payload, 'msg->size()');
is($msg->channel_number(), 1, 'msg->channel_number()');
is($msg->payload(), $payload, 'msg->payload()');
is($msg->size(), length $payload, 'msg->size()');
is($msg->content(), $payload, 'msg->content()');
is($msg->content_type(), 'application/octet-stream',
   'msg->content_type() default');
is($msg->content_encoding(), 'binary', 'msg->content_encoding() default');

# some of the accessor methods allow us to change the values.
$msg->type('RPY');
is($msg->type(), 'RPY', 'msg->type($val)');

$msg->msgno(12);
is($msg->msgno(), 12, 'msg->msgno($val)');

# payload <-> content
my $content = 'Some kind of content!';
$msg = new Net::BEEP::Lite::Message(Type 	  => 'MSG',
				  Channel => 1,
				  Content => $content);
is($msg->payload(), $content, 'content->payload w/ no MIME stuff');
is($msg->size(), length $content, 'content->payload w/no MIME stuff (size)');

$msg = new Net::BEEP::Lite::Message(Type 	      => 'MSG',
				  Channel     => 1,
				  Content     => $content,
				  ContentType => 'text/plain');
my $c_to_p = "Content-Type: text/plain\r\n\r\n$content";
is($msg->payload(), $c_to_p, 'content->payload w/ MIME');
is($msg->size(), length $c_to_p, 'content->payload w/ MIME (size)');

# next_frame

# first we need to build a content large enough to fragment.  We will
# be setting the window size abnormally small, however, so it
# shouldn't be all that hard.

my $large_content = join("", 1..150) . "\n";

$msg = new Net::BEEP::Lite::Message(Type 		   => 'RPY',
				  Channel 	   => 1,
				  Msgno 	   => 12,
				  Content 	   => $large_content,
				  Content_Type 	   => "text/plain",
				  Content_Encoding => "utf-8");
my $large_payload
  = "Content-Type: text/plain\r\nContent-Transfer-Encoding: utf-8\r\n\r\n" .
  $large_content;

is($msg->payload(), $large_payload, "content->payload w/MIME encoding");

my $frame = $msg->next_frame(0, 256);
is($frame->payload(), substr($large_payload, 0, 256), "msg->next_frame() 1");
is($frame->size(), 256, "msg->next_frame()->size() 1");
is($frame->seqno(), 0, "msg->next_frame()->seqno() 1");
ok($msg->has_more_frames(), 'msg->has_more_frames() is true');

my $frame2 = $msg->next_frame(0 + $frame->size(), 256);
is($frame2->payload(), substr($large_payload, 256), "msg->next_frame() 2");
is($frame2->size(), length($large_payload) - 256,
   "msg->next_frame()->size() 2");
is($frame2->seqno(), 256, "msg->next_frame->seqno() 2");

ok(! $msg->has_more_frames(), 'msg->has_more_frames() is false');
my $frame3 = $msg->next_frame(0 + $frame->size() + $frame2->size(), 256);
is($frame3, undef, "msg->next_frame() 3");

# reset_frames

$msg->reset_frames();

my $frame4 = $msg->next_frame(0, 256);
is($frame4->to_string(), $frame->to_string(), "msg->reset_frames()");


# add_frame

$msg = new Net::BEEP::Lite::Message(Frame   => $frame);
$msg->add_frame($frame2);

is($msg->payload(), $large_payload, 'msg->add_frame()');

# make sure a frame-built message get the MIME decoded stuff.
is($msg->content(), $large_content, 'frame-built message decodes MIME 1');
is($msg->content_type(), "text/plain", 'frame-built message decodes MIME 2');
is($msg->content_encoding(), "utf-8", 'frame-built message decodes MIME 3');

# check next_frame against zero length payloads.
$msg = new Net::BEEP::Lite::Message(Type 	  => 'NUL',
				  Channel => 1,
				  Msgno	  => 15);
ok($msg->has_more_frames(),
   'msg->has_more_frames() true for null payload message');
$frame = $msg->next_frame(0, 256);
ok($frame, "msg->next_frame generated first frame of null payload msg");
ok(! $msg->has_more_frames(), "msg->has_more_frames() now false");
$frame2 = $msg->next_frame(0, 256);
is($frame2, undef, 'msg->next_frame() returned undef');
