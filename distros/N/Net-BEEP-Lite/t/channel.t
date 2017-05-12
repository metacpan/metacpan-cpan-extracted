# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 3.t'

#########################

use Test::More tests => 26;
#use Test::More qw(no_plan);

BEGIN { use_ok('Net::BEEP::Lite::Channel');
        use_ok('Net::BEEP::Lite::Message'); };

#########################

# Testing Net::BEEP::Lite::Channel

# the constructor:
my $channel = Net::BEEP::Lite::Channel->new;
ok(defined $channel, 'constructor works');
isa_ok($channel, 'Net::BEEP::Lite::Channel');

# a fake profile
my $fake_profile = {};

# create a real channel
$channel = new Net::BEEP::Lite::Channel(Number  => 1,
				      Window  => 1024,
				      Profile => $fake_profile);

# make sure the basic accessors work
is($channel->profile(), $fake_profile, 'channel->profile()');
is($channel->seqno(), 0, 'channel->seqno()');
is($channel->msgno(), 0, 'channel->msgno()');
is($channel->msgno(11), 11, 'channel->msgno(val)');
is($channel->next_msgno(), 11, 'channel->next_msgno() 1');
is($channel->next_msgno(), 12, 'channel->next_msgno() 2');
is($channel->local_window(), 1024, 'channel->local_window()');
is($channel->local_window(2048), 2048, 'channel->local_window(val)');
is($channel->remote_window(), 4096, 'channel->remote_window() default');
is($channel->remote_window(3990), 3990, 'channel->remote_window(val)');
is($channel->number(), 1, 'channel->number');

# sequence numbers
$channel->update_seqno(112);
is($channel->seqno(), 112, "channel->update_seqno() 1");
$channel->update_seqno(2);
is($channel->seqno(), 114, "channel->update_seqno() 2");

# rollovers
$channel->msgno(2147483646);
is($channel->next_msgno(), 2147483646, 'channel->msgno rollover 1');
is($channel->next_msgno(), 2147483647, 'channel->msgno rollover 2');
is($channel->next_msgno(), 0, 'channel->msgno rollover 3');

$channel->{seqno} = 4294967295;
is($channel->seqno(), 4294967295, 'channel->seqno() rollover 1');
$channel->update_seqno(1);
is($channel->seqno(), 0, 'channel->seqno() rollover 2');
$channel->{seqno} = 4294967290;
$channel->update_seqno(10);
is($channel->seqno(), 4, 'channel->seqno() rollover 3');

# The message building slots.

# normal messages.

my $large_content = join("", 1..150) . "\n";

my $msg = new Net::BEEP::Lite::Message(Type    => 'RPY',
				     Msgno   => 12,
				     Channel => 1,
				     Content => $large_content);
my $large_payload = $msg->payload();

my $frame1 = $msg->next_frame(0, 256);
my $frame2 = $msg->next_frame(256, 256);

$channel->message_add_frame($frame1);
$channel->message_add_frame($frame2);

my $ch_msg = $channel->message();
# force content conversion.
$ch_msg->content();
# force internal frame state to known values.
$msg->reset_frames();

# note: this is pretty fragile.  We might be better off testing all of
# the known subcomponents here.
is_deeply($ch_msg, $msg, 'constructed message same as orig.');

$channel->clear_message();
is($channel->message(), undef, 'channel->clear_message()');

# ANS messages.

$msg = new Net::BEEP::Lite::Message(Type 	  => 'ANS',
				  Msgno   => 13,
				  Ansno   => 1,
				  Channel => 1,
				  Content => $large_content);
$frame1 = $msg->next_frame(0, 256);
$frame2 = $msg->next_frame(256, 256);

$channel->ans_message_add_frame($frame1);
$channel->ans_message_add_frame($frame2);

$ch_msg = $channel->ans_message($frame1->ansno());
$ch_msg->content();
$msg->reset_frames();

is_deeply($ch_msg, $msg, 'constructed ans message same as orig.');

