# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 5.t'

#########################

use Test::More tests => 62;
#use Test::More qw(no_plan);

BEGIN { use_ok('Net::BEEP::Lite::MgmtProfile');
        use_ok('Net::BEEP::Lite::Message');
        use_ok('Net::BEEP::Lite::Session');
        use_ok('XML::LibXML');                };

#########################

# Testing Net::BEEP::Lite::MgmtProfile

# the constructor:
my $mgmt = Net::BEEP::Lite::MgmtProfile->new;
ok(defined $mgmt, 'constructor works');
isa_ok($mgmt, 'Net::BEEP::Lite::MgmtProfile');
isa_ok($mgmt, 'Net::BEEP::Lite::BaseProfile');

$mgmt = Net::BEEP::Lite::MgmtProfile->new(AllowMultipleChannels => 1);
is($mgmt->allow_multiple_channels(), 1, 'mgmt->allow_multiple_channels()');

$mgmt->allow_multiple_channels(0);
is($mgmt->allow_multiple_channels(), 0, 'mgmt->allow_multiple_channels($val)');


# test the management message creation routines.

# for that, we need some (fake) profiles.
my $fake_profile = { uri => "http://host.example.com/some/profile" };
bless $fake_profile, 'Net::BEEP::Lite::BaseProfile';

# a session.
my $session = new Net::BEEP::Lite::Session();
$session->add_local_profile($fake_profile);

# and an XML parser.
my $parser = XML::LibXML->new();

# The greeting message.

my $msg = $mgmt->greeting_message($session->get_local_profile_uris());
isa_ok($msg, 'Net::BEEP::Lite::Message', 'mgmt->greeting_message()');
is($msg->content_type(), 'application/beep+xml',
   'greeting message content type');
is($msg->type(), 'RPY', 'greeting message is a RPY');

my $root = $parser->parse_string($msg->content())->documentElement();
is($root->nodeName, "greeting", 'greeting msg is greeting element');

my @children = $root->childNodes;
for my $child (@children) {
  if ($child->isa('XML::LibXML::Element')) {
    is($child->nodeName, "profile", 'and has profile child element');
    is($child->getAttribute('uri'), "http://host.example.com/some/profile",
       'and has profile with correct uri');
  }
}

# the start channel message

$msg = $mgmt->start_channel_message
  (URI        => "http://host.example.com/some/profile",
   Channel    => 1,
   ServerName => "host.example.com",
   StartData  => "starting data");

is($msg->type(), 'MSG', 'start message is MSG');
$root = $parser->parse_string($msg->content())->documentElement();
is($root->nodeName, "start", "start message has start element");
is($root->getAttribute('number'), 1, 'has expected channel number');
is($root->getAttribute('serverName'), 'host.example.com', 'has serverName');
@children = $root->childNodes;
for my $child (@children) {
  if ($child->isa('XML::LibXML::Element')) {
    is($child->nodeName, "profile", 'has profile child element');
    is($child->getAttribute('uri'), 'http://host.example.com/some/profile',
       'has correct profile uri');
    is($child->textContent, 'starting data', 'has starting data');
  }
}

# the close channel message.
my $close_content = 'this is some close content';

$msg = $mgmt->close_channel_message(1, 220, $close_content, 'en-US');
is($msg->type(), 'MSG', 'close message is MSG');
$root = $parser->parse_string($msg->content())->documentElement();
is($root->nodeName, 'close', 'close message has close element');
is($root->getAttribute('number'), 1, 'has correct channel number');
is($root->getAttribute('code'), 220, 'has correct code attribute');
is($root->textContent, $close_content, 'has correct text content');

# profile message

my $profile_data = "response to start data";

$msg = $mgmt->profile_message(11, 'http://host.example.com/some/profile',
			      $profile_data, 0);

is($msg->type(), 'RPY', 'profile message is RPY');
$root = $parser->parse_string($msg->content())->documentElement();
is($root->nodeName, 'profile', 'has profile element');
is($root->getAttribute('uri'), 'http://host.example.com/some/profile',
   'has correct URI');
is($root->textContent, $profile_data, 'and has correct profile content');

# error message creation

$msg = $mgmt->_error_message(11, 543, 'some error content');
is($msg->type(), 'ERR', 'error messages are ERR');
is($msg->content_type(), 'application/beep+xml', 'has correct content type');
$root = $parser->parse_string($msg->content())->documentElement();
is($root->nodeName, 'error', 'has error element');
is($root->getAttribute('code'), 543, 'has correct code attribute.');
is($root->textContent, 'some error content', 'has correct error content');


## Testing the profile itself.

# for this, we need to fake the socket.  We do this with IO::Stringy,
# which is optional.  So we will skip the tests if it is not
# available.


SKIP:
{
  eval { require IO::Lines; };
  skip "IO::Stringy (and specifically IO::Lines) not installed", 26 if $@;

  my @output_lines;
  $session->{sock} = new IO::Lines(\@output_lines);

  sub msg_from_lines {
    my $header = shift;
    my $frame = new Net::BEEP::Lite::Frame(Header => $header);
    my $payload = join('', @_);
    $frame->set_payload(substr($payload, 0, $frame->size()));
    new Net::BEEP::Lite::Message(Frame => $frame);
  }

  # For now, we mainly test correct cases.  It is a known TODO to
  # check and handle more errors in general.

  # MSGs.  These include start and close message.
  my $uri = $fake_profile->uri();

  my $channel_zero = $session->channel(0);
  my $orig_window = $channel_zero->remote_window();

  # the greeting message.
  @output_lines = ();
  $channel_zero->remote_window($orig_window);
  $mgmt->send_greeting_message($session);

  $msg = msg_from_lines(@output_lines);
  is($msg->type(), 'RPY', 'sent greeting message was RPY');

  $root = $parser->parse_string($msg->content())->documentElement();
  is($root->nodeName, "greeting", 'greeting msg is greeting element');

  my @children = $root->childNodes;
  for my $child (@children) {
    if ($child->isa('XML::LibXML::Element')) {
      is($child->nodeName, "profile", 'and has profile child element');
      is($child->getAttribute('uri'), "http://host.example.com/some/profile",
	 'and has profile with correct uri');
    }
  }

  @output_lines = ();
  $channel_zero->remote_window($orig_window);
  $mgmt->handle_message($session, $msg);
  is(scalar @output_lines, 0, 'greeting message generated no response');


  # the start message.

  # FIXME: we should test startChannelData, but our fake session
  # doesn't have a real profile that can handle it.

  my ($open_channel_num)
    = $mgmt->send_start_channel_message($session,
					(URI        => $uri,
					 ServerName => "host.example.com"));
  my $msg = msg_from_lines(@output_lines);

  is($session->{starting_channel_number}, $open_channel_num,
     'send_start_channel_message set "starting_channel_number" ' .
     'in the session');

  my $msgno = $msg->msgno();
  ok($msgno > 0, "send_start_channel_message assigned msgno: $msgno");

  @output_lines = ();
  $channel_zero->remote_window($orig_window);
  $mgmt->handle_message($session, $msg);

  my $resp = msg_from_lines(@output_lines);

  is($resp->type(), 'RPY', 'response to start channel is RPY');
  is($resp->content_type, 'application/beep+xml', 'has correct content type');
  is($resp->msgno(), $msgno, 'has correct message number');
  $root = $parser->parse_string($resp->content())->documentElement();
  is($root->nodeName, 'profile', 'and is a profile element');

  # send a second start channel request that should be refused.
  $mgmt->allow_multiple_channels(0);

  @output_lines = ();
  $channel_zero->remote_window($orig_window);
  $msg->reset_frames();
  $msg->msgno($msgno + 1);

  $mgmt->handle_message($session, $msg);
  $resp = msg_from_lines(@output_lines);

  is($resp->type(), 'ERR', 'response to disallowed start channel is ERR');
  is($resp->msgno(), $msg->msgno(), 'has correct message number');
  $root = $parser->parse_string($resp->content)->documentElement();
  is($root->nodeName, 'error', 'and is an error element');

  # The close message

  # close our just opened channel.
  @output_lines = ();
  $channel_zero->remote_window($orig_window);
  $mgmt->send_close_channel_message($session, $open_channel_num);
  $msg = msg_from_lines(@output_lines);

  is($msg->type(), 'MSG', 'sent close channel message was MSG');
  is($msg->channel_number(), 0,
     'sent close channel message was on chan. zero');
  is($session->{closing_channel_number}, $open_channel_num,
     'send_close_channel_message set "closing_channel_number" in the session');
  $msgno = $msg->msgno();

  @output_lines = ();
  $channel_zero->remote_window($orig_window);
  $mgmt->handle_message($session, $msg);
  $resp = msg_from_lines(@output_lines);

  is($resp->type(), 'RPY', 'response to close message is RPY');
  is($resp->msgno(), $msgno, 'has correct message number');
  is($resp->channel_number(), 0, "has correct channel number");
  $root = $parser->parse_string($resp->content)->documentElement();
  is($root->nodeName, 'ok', 'has an ok element');


  # Replies:  this includes greeting, profile, and ok responses.

  # lets create a greeting with multiple advertised profiles. To do
  # that, we need to add some more (fake) profiles to our session
  my $fake_profile2 = { uri => "http://host.example.com/some/profile2" };
  bless $fake_profile2, 'Net::BEEP::Lite::BaseProfile';
  my $fake_profile3 = { uri => "http://host.example.com/some/profile3" };
  bless $fake_profile3, 'Net::BEEP::Lite::BaseProfile';
  $session->add_local_profile($fake_profile2);
  $session->add_local_profile($fake_profile3);

  @output_lines = ();
  $channel_zero->remote_window($orig_window);

  $mgmt->send_greeting_message($session);
  $msg = msg_from_lines(@output_lines);

  is($msg->msgno(), 0, 'greeting always is message 0 for us');

  $mgmt->handle_message($session, $msg);

  ok($session->has_remote_profile('http://host.example.com/some/profile3'),
    'has third remote profile');
  ok($session->has_remote_profile('http://host.example.com/some/profile2'),
    'has second remote profile');
  ok($session->has_remote_profile('http://host.example.com/some/profile'),
    'has first remote profile');

  # profile

  @output_lines = ();
  $channel_zero->remote_window($orig_window);

  # note that this test is pretty feeble.
  $mgmt->send_profile_message($session, 16,
			      'http://host.example.com/some/profile2');
  $msg = msg_from_lines(@output_lines);

  # we have to fake the starting channel number bit.  this would
  # normally be set by the send_start_channel_message routine.
  $session->{starting_channel_number} = 7;

  @output_lines = ();
  $channel_zero->remote_window($orig_window);

  $mgmt->handle_message($session, $msg);
  $new_channel = $session->channel(7);
  ok($new_channel, 'profile message added channel');

}
