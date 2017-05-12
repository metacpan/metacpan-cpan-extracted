# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 5.t'

#########################

use Test::More tests => 67;
# use Test::More qw(no_plan);

BEGIN {
  use_ok('Net::BEEP::Lite::Session');
  use_ok('Net::BEEP::Lite::Message');
  use lib "./t";
};

#########################

# Testing Net::BEEP::Lite::Session

# the constructor:
my $session = Net::BEEP::Lite::Session->new();
ok(defined $session, 'constructor works');
isa_ok($session, 'Net::BEEP::Lite::Session');

# create a fake profile
my $fake_profile_uri = 'http://host.example.com/some/profile1';
my $fake_profile = { uri => $fake_profile_uri };
bless $fake_profile, 'Net::BEEP::Lite::BaseProfile';

my $fake_profile_uri2 = 'http://host.example.com/some/other/profile';
my $fake_profile2 = { uri => $fake_profile_uri2 };
bless $fake_profile2, 'Net::BEEP::Lite::BaseProfile';

# there are not many things we can test without a socket (or even the
# fake socket we will use later on).  Someday, it might be a good idea
# to refactor the internals so they are easier to test.

# start with basic channel creation, counters.

$session->_add_channel(2, $fake_profile);
my $channel_2 = $session->channel(2);
isa_ok($channel_2, 'Net::BEEP::Lite::Channel');
is($session->num_open_channels(), 1, 'num_open_channels() 1');

$session->_del_channel(2);
$channel_2 = $session->channel(2);
is($channel_2, undef, '_del_channel(2) worked');
is($session->num_open_channels(), 0, 'num_open_channels() 2');

my $next_chno = $session->_next_channel_number();
is($next_chno, 1, '_next_channel_number returned expected channel (1)');

my $next_next_chno = $session->_next_channel_number();
is($next_next_chno, 3, '_next_channel_number incremented correctly');

# test channel number rollover here.
$session->{channelno_counter} = 2147483647;
is($session->_next_channel_number(), 2147483647,
   '_next_channel_number rollover 1');
is($session->_next_channel_number(), 1,
   '_next_channel_number rollover 2');

# add a channel that we will work with for a while.
$session->_add_channel($next_chno, $fake_profile);

# test basic profile management (not channel related).

$session->add_local_profile($fake_profile);
$session->add_local_profile($fake_profile2);

is($session->get_local_profile($fake_profile_uri), $fake_profile,
   'get_local_profile worked');
is($session->get_local_profile_uris(), 2, 'get_local_profile_uris()');

$session->add_remote_profile($fake_profile_uri2);
ok($session->has_remote_profile($fake_profile_uri2), 'has_remote_profile');
$session->add_remote_profile($fake_profile_uri);
is($session->remote_profiles(), 2, 'remote_profiles()');

my $test_servername = 'some.host.example.net';
is($session->servername(), undef, 'servername starts out undef');
is($session->servername($test_servername), $test_servername,
   'servername($val)');
is($session->servername(), $test_servername, 'servername()');

# For the rest, we need a fake socket, which relies on a package that
# may not be installed.

SKIP:
{
  eval { require IO::Scalar;
         require FullDuplexScalar; };
  print $@;
  skip "IO::Stringy (and specifically IO::Scalar) not installed", 48 if $@;

  my $output;
  my $fake_socket = new IO::Scalar(\$output);

  $session = new Net::BEEP::Lite::Session(Socket => $fake_socket);

  # and we will setup a channel, bypassing the normal way to do it (in
  # the MgmtProfile code).
  $session->_add_channel(2, $fake_profile);
  $channel_2 = $session->channel(2);
  $channel_2->update_seqno(120);

  # _write_frame

  my $frame_payload = "Content-Type: text/plain\r\n\r\nSome Content!. Whee!\n";
  my $frame_payload_size = length $frame_payload;
  my $frame_expect_result = "ANS 2 2 . 120 $frame_payload_size 0\r\n" .
    $frame_payload . "END\r\n";
  my $frame = new Net::BEEP::Lite::Frame
    (Type    => 'ANS',
     Channel => 2,
     Msgno   => 2,
     Ansno   => 0,
     More    => '.',
     Size    => $frame_payload_size,
     Seqno   => $channel_2->seqno(),
     Payload => $frame_payload);

  $session->_write_frame($frame);
  is($output, $frame_expect_result, '_write_frame did the expected');

  # _read_frame
  $output = $frame_expect_result;
  $fake_socket->seek(0, 0);
  $frame = $session->_read_frame();
  is($frame->type(), 'ANS', "_read_frame: right type");
  is($frame->size(), $frame_payload_size, "_read_frame: right size");
  is($frame->ansno(), 0, "_read_frame: right ansno");

  # FIXME: test _read_frame body timeout

  # _recv_frame:

  # need to test: SEQ handling, that it put the frame in the right
  # build spot.

  # artifically set our (sending) seqno
  $channel_2->{seqno} = 120;

  # generate some content to read.
  $frame = new Net::BEEP::Lite::Frame(Type    => 'MSG',
                                      Channel => 2,
                                      Msgno   => 3,
                                      More    => '.',
                                      Seqno   => 200,
                                      Payload => $frame_payload);
  $output = "SEQ 2 100 4096\r\n" . $frame->to_string();
  $fake_socket->seek(0,0);

  $frame = $session->_recv_frame();

  is($frame->type(), 'SEQ', '_recv_frame read correct frame');
  is($channel_2->remote_window(), 4096 - 20,
     '_recv_frame updated remote window correctly');

  $frame = $session->_recv_frame();

  is($frame->type(), 'MSG', '_recv_frame read correct next frame');
  is($frame->payload(), $frame_payload, 'and has correct payload');
  isnt($channel_2->message(), undef, 'and put in in the correct slot');
  is($channel_2->message()->payload(), $frame_payload, 'correct slot test 2');

  $channel_2->clear_message();

  my $ans_frame = new Net::BEEP::Lite::Frame
    (Type    => 'ANS',
     Channel => 2,
     Msgno   => 2,
     Ansno   => 12,
     More    => '.',
     Seqno   => 1234,
     Payload => $frame_payload);

  $output = $ans_frame->to_string();
  my $output_length = length $output;
  $fake_socket->seek(0,0);

  $frame = $session->_recv_frame();
  is($frame->payload(), $ans_frame->payload(), "_recv_frame read ANS frame.");

  isnt($channel_2->ans_message(12), undef, '_recv_frame placed ANS frame');
  is($channel_2->ans_message(12)->payload(), $frame_payload,
     '_recv_frame ANS frame test 2');

  $fake_socket->seek($output_length, 0);
  $frame = $session->_read_frame();
  is($frame->type(), 'SEQ', '_recv_frame generated SEQ');
  is($frame->channel_number(), 2, '_recv_frame generated SEQ channel number');
  is($frame->ackno(), 1234 + $frame_payload_size,
     '_recv_frame generated SEQ ackno');
  is($frame->window(), $channel_2->local_window(),
     '_recv_frame generated SEQ window');

  # _recv_message

  # to test the higher level primitives, we need a better fake socket.
  # we will create a new session, just to reset everything.

  my $input; $output = undef;
  $fake_socket = new FullDuplexScalar(\$input, \$output);
  $session = new Net::BEEP::Lite::Session(Socket => $fake_socket);

  # test interleaved messages on three channels (this has a long
  # setup):
  $session->_add_channel(1, $fake_profile);
  $session->_add_channel(3, $fake_profile);
  $session->_add_channel(5, $fake_profile);

  my $tmp = join('', 'A'..'Z') . join('', 'a'..'z') . join('', 0..9);
  my $full_content = $tmp . $tmp . $tmp . $tmp . $tmp;

  # create three similar messages on three different channels
  my @msgs;
  for (my $i = 0; $i < 3; $i++) {
    $msgs[$i] = new Net::BEEP::Lite::Message(Type    => 'MSG',
					   Msgno   => 1,
					   Channel => ($i * 2) + 1,
					   Content => $full_content);
  }
  # load all of the 100 byte or less frames into this list of lists.
  my @frames;
  for (my $i = 0; $i < 3; $i++) {
    my $msg = $msgs[$i];
    my $fs = [];
    my $seqno = 0;
    while (my $frame = $msg->next_frame($seqno, 150)) {
      push @$fs, $frame;
      $seqno += $frame->size();
    }
    $frames[$i] = $fs;
  }

  # now construct the actual input sequence.
  my @sequence = ([0,0], [2,0], [2,1], [1,0], [0,1], [2,2],
		  [1,1], [1,2], [0,2]);
  for my $i (@sequence) {
    $input .= $frames[$i->[0]]->[$i->[1]]->to_string();
  }
  # construct our expected output sequence This is based on emitting a
  # static window size after reading each frame.
  my $expected_output;
  for my $i (@sequence) {
    my $chno = ($i->[0] * 2) + 1;
    my $seqno;
    $seqno = ($i->[1] + 1) * 150 if $i->[1] < 2;
    $seqno = 310 if $i->[1] == 2;
    $expected_output .= "SEQ $chno $seqno 4096\r\n";
  }

  my $msg = $session->_recv_message();
  is($msg->content(), $full_content, "msg 1 has correct content");
  is($msg->channel_number(), 5, "msg 1 has correct channel number.");
  is($msg->msgno(), 1, "msg 1 has correct msgno");
  is($msg->type(), 'MSG', "msg 1 has correct type");
  is($session->channel(5)->message(), undef, "msg 1 was cleared from slot");
  isnt($session->channel(3)->message(), undef, "msg 2 is still in slot");

  $msg = $session->_recv_message();
  is($msg->channel_number, 3, "msg 2 has correct channel number.");
  is($msg->content(), $full_content, "msg 2 has correct content.");
  is($session->channel(3)->message(), undef, "msg 2 was cleared from slot");

  $msg = $session->_recv_message();
  is($msg->channel_number, 1, "msg 3 has correct channel number.");
  is($msg->content(), $full_content, "msg 3 has correct content.");
  is($session->channel(1)->message(), undef, "msg 3 was cleared from slot");

  is($output, $expected_output, "output of SEQs matches expected.");

  # Test interleaved ANS messages on the same and different channels
  # (again, a fairly long setup):

  $input = ''; $output = '';
  $fake_socket->in()->seek(0,0);
  $fake_socket->out()->seek(0,0);

  # create 4 ans messages: 3 on one channel, 1 on another.
  for (my $i = 0; $i < 4; $i++) {
    $msgs[$i] = new Net::BEEP::Lite::Message(Type    => 'ANS',
					   Msgno   => 12,
					   Ansno   => $i == 3 ? 0 : $i,
					   Channel => $i == 3 ? 3 : 1,
					   Content => $full_content);
  }
  # generate all of the frames:
  for (my $i = 0; $i < 4; $i++) {
    my $msg = $msgs[$i]; my @f; my $seqno = 0;
    while (my $frame = $msg->next_frame($seqno, 100)) {
      push @f, $frame;
      $seqno += $frame->size();
    }
    $frames[$i] = \@f;
  }

  # generate an input sequence
  @sequence = ( [0, 0], [1, 0], [2, 0], [3, 0], [2, 1], [2, 2], [0, 1],
		[3, 1], [1, 1], [0, 2], [3, 2], [1, 2], [0, 3], [1, 3],
		[2, 3], [3, 3] );
  for my $i (@sequence) {
    $input .= $frames[$i->[0]]->[$i->[1]]->to_string();
  }

  $msg = $session->_recv_message();
  is($msg->channel_number(), 1, 'ANS msg 1 channel number');
  is($msg->ansno(), 0, 'ANS msg 1 ansno');
  is($msg->content(), $full_content, 'ANS msg 1 content');
  is($session->channel(1)->ans_message(0), undef, 'ANS msg 1 cleared');

  $msg = $session->_recv_message();
  is($msg->channel_number(), 1, 'ANS msg 2 channel number');
  is($msg->ansno(), 1, 'ANS msg 2 ansno');
  is($msg->content(), $full_content, 'ANS msg 2 content');

  $msg = $session->_recv_message();
  is($msg->channel_number(), 1, 'ANS msg 3 channel number');
  is($msg->ansno(), 2, 'ANS msg 3 ansno');
  is($msg->content(), $full_content, 'ANS msg 3 content');

  $msg = $session->_recv_message();
  is($msg->channel_number(), 3, 'ANS msg 4 channel number');
  is($msg->ansno(), 0, 'ANS msg 4 ansno');
  is($msg->content(), $full_content, 'ANS msg 4 content');

  # not bothering to set the SEQ output, as that has probably been
  # adequately done by the first interleave test.

  # send_message

  # try and send a message that must be fragmented, based on a really
  # small remote window size.  Then the send_message routine must then
  # wait for a SEQ.  Instead of immediately getting the requested SEQ,
  # it gets a full message and a SEQ for a different channel.

  $input = ''; $output = '';
  $fake_socket->in()->seek(0,0);
  $fake_socket->out()->seek(0,0);

  $session->channel(5)->remote_window(200);

  my $outgoing_msg = new Net::BEEP::Lite::Message(Type 	  => 'MSG',
						  Channel => 5,
						  Content => $full_content);
  my $incoming_msg = new Net::BEEP::Lite::Message(Type 	  => 'RPY',
						  Msgno   => 1,
						  Channel => 5,
						  Content => $full_content);
  # construct input.
  $input = $incoming_msg->next_frame(310, 150)->to_string() .
    "SEQ 3 310 4096\r\n" . $incoming_msg->next_frame(460, 150)->to_string() .
      $incoming_msg->next_frame(610, 150)->to_string() .
      "SEQ 5 410 200\r\n" . "SEQ 5 620 200\r\n";
  # set our (sending) seqno to 310.
  $session->channel(5)->update_seqno(310);

  # this should be put into three frames: 200, 100, and 10 bytes long
  # respectively.
  $session->send_message($outgoing_msg);

  # construct expected output (minus SEQ frames generated while
  # waiting for our needed SEQ):

  $outgoing_msg->reset_frames();
  $expected_output = $outgoing_msg->next_frame(310, 200)->to_string();
  $expected_output .= $outgoing_msg->next_frame(510, 100)->to_string();
  $expected_output .= $outgoing_msg->next_frame(610, 200)->to_string();

  my $generated_output;
  my @l = split(/\n/, $output);
  for my $l (@l) {
    next if $l =~ /^SEQ/;
    $generated_output .= $l . "\n";
  }

  is($generated_output, $expected_output, 'generated output matches expected');
  is(@{$session->{messages}}, 1, 'a message is on the general message queue');

  # get the message on the queue.
  $msg = $session->_recv_message();
  is($msg->type(), $incoming_msg->type(), "queued message has right type");
  is($msg->content(), $incoming_msg->content(),
     "queued message has right content");
  is($msg->msgno(), $incoming_msg->msgno(), "queued message has right msgno");
}
