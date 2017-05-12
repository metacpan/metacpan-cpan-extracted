#! /usr/local/bin/perl
#---------------------------------------------------------------------
# Test Telephony::Asterisk::AMI with active Event_Callback
#
# Copyright 2015 Christopher J. Madsen
#---------------------------------------------------------------------

use 5.008;
use strict;
use warnings;

use Test::More 0.88 tests => 31; # done_testing
use t::Fake_Socket;

use Telephony::Asterisk::AMI ();

set_input(<<'END INPUT 1');
Asterisk Call Manager/2.8.0
Response: Success
ActionID: 1
Message: Authentication accepted

Event: FullyBooted
Privilege: system,all
Status: Fully Booted

Event: SuccessfulAuth
Privilege: security,all
EventTV: 2015-11-28T11:56:38.090-0600
Severity: Informational
Service: AMI
EventVersion: 1
AccountID: monitor
SessionID: 0x7fdef0015978
LocalAddress: IPV4/TCP/0.0.0.0/5038
RemoteAddress: IPV4/TCP/127.0.0.1/34314
UsingPassword: 0
SessionTV: 2015-11-28T11:56:38.090-0600

Response: Error
ActionID: 2
Message: Extension does not exist.

Event: InOrder
Single: This field appears once.
Double: This field appears
Double: two times.
Triple: This field appears
Triple: three
Triple: times.

Event: MixedOrder
Double: This field appears
Triple: This field appears
Single: This field appears once.
Triple: three
Double: two times.
Triple: times.

Response: Success
ActionID: 3
Ping: Pong
Timestamp: 1448733398.096444

Response: Success
ActionID: 4
CoreStartupDate: 2015-11-15
CoreStartupTime: 10:41:57
CoreReloadDate: 2015-11-15
CoreReloadTime: 15:36:37
CoreCurrentCalls: 0

Response: Success
ActionID: 5
Single: This field appears once.
Double: This field appears
Double: two times.
Triple: This field appears
Triple: three
Triple: times.

Response: Success
ActionID: 6
Double: This field appears
Triple: This field appears
Single: This field appears once.
Triple: three
Double: two times.
Triple: times.

Response: Goodbye
ActionID: 7
Message: Thanks for all the fish.

END INPUT 1

my @events;

my $ami = Telephony::Asterisk::AMI->new(
  Username => 'user',
  Secret => 'secret',
  Event_Callback => sub { push @events, @_ },
  #Debug => 1,
);

isa_ok($ami, 'Telephony::Asterisk::AMI');

is_deeply(\@events, [], 'no events from constructor');
@events = ();

#.....................................................................
ok($ami->connect, "connected");

is_deeply(
  socket_args,
  {
    Type => IO::Socket::IP::SOCK_STREAM(),
    PeerHost => 'localhost',
    PeerService => 5038,
  },
  'socket args correct');

is($ami->error, undef, 'connect did not set error');

is_deeply(\@events, [], 'no events from connect');
@events = ();

is(socket_output,
   "ActionID: 1\r\nAction: Login\r\nSecret: secret\r\nUsername: user\r\n\r\n",
   'connect output correct');

#.....................................................................
is_deeply(
  $ami->action({
    Action => 'Originate',
    Channel => 'LOCAL/invalid',
    Exten => '100',
    Context => 'default',
    Priority => '1',
    Variable => [ 'VAR1=v1', 'VAR2=v2' ],
  }),
  {
    ActionID => 2,
    Message  => "Extension does not exist.",
    Response => "Error",
  },
  'Originate error');

is($ami->error, undef, 'Originate did not set error');

is_deeply(\@events, [
    {
      Event     => "FullyBooted",
      Privilege => "system,all",
      Status    => "Fully Booted",
    },
    {
      Event         => "SuccessfulAuth",
      AccountID     => "monitor",
      EventTV       => "2015-11-28T11:56:38.090-0600",
      EventVersion  => 1,
      LocalAddress  => "IPV4/TCP/0.0.0.0/5038",
      Privilege     => "security,all",
      RemoteAddress => "IPV4/TCP/127.0.0.1/34314",
      Service       => "AMI",
      SessionID     => "0x7fdef0015978",
      SessionTV     => "2015-11-28T11:56:38.090-0600",
      Severity      => "Informational",
      UsingPassword => 0,
    },
  ], 'events during Originate');
@events = ();

is(socket_output,
   "ActionID: 2\r\nAction: Originate\r\nChannel: LOCAL/invalid\r\n"
       . "Context: default\r\nExten: 100\r\nPriority: 1\r\n"
       . "Variable: VAR1=v1\r\nVariable: VAR2=v2\r\n\r\n",
   'Originate output correct');

#.....................................................................
is_deeply(
  $ami->action(Action => 'Ping'),
  {
    ActionID  => 3,
    Ping      => "Pong",
    Response  => "Success",
    Timestamp => "1448733398.096444",
  },
  'Ping successful');

is($ami->error, undef, 'Ping did not set error');

is_deeply(\@events, [
    {
      Event  => "InOrder",
      Single => "This field appears once.",
      Double => ["This field appears", "two times."],
      Triple => ["This field appears", "three", "times."],
    },
    {
      Event  => "MixedOrder",
      Single => "This field appears once.",
      Double => ["This field appears", "two times."],
      Triple => ["This field appears", "three", "times."],
    },
  ], 'events during Ping');
@events = ();

is(socket_output,
   "ActionID: 3\r\nAction: Ping\r\n\r\n",
   'Ping output correct');

#.....................................................................
is_deeply(
  $ami->action(Action => 'CoreStatus'),
  {
    ActionID  => 4,
    CoreCurrentCalls => 0,
    CoreReloadDate   => "2015-11-15",
    CoreReloadTime   => "15:36:37",
    CoreStartupDate  => "2015-11-15",
    CoreStartupTime  => "10:41:57",
    Response         => "Success",
  },
  'CoreStatus successful');

is($ami->error, undef, 'CoreStatus did not set error');

is_deeply(\@events, [], 'no events during CoreStatus');
@events = ();

is(socket_output,
   "ActionID: 4\r\nAction: CoreStatus\r\n\r\n",
   'CoreStatus output correct');

#.....................................................................
is_deeply(
  $ami->action(Action => 'TestInput'),
  {
    ActionID => 5,
    Response => "Success",
    Single => 'This field appears once.',
    Double => [ 'This field appears', 'two times.' ],
    Triple => [ 'This field appears', 'three', 'times.' ],
  },
  'TestInput successful');

is($ami->error, undef, 'TestInput did not set error');

is_deeply(\@events, [], 'no events during TestInput');
@events = ();

is(socket_output,
   "ActionID: 5\r\nAction: TestInput\r\n\r\n",
   'TestInput output correct');

#.....................................................................
is_deeply(
  $ami->action(Action => 'TestInputMixed'),
  {
    ActionID => 6,
    Response => "Success",
    Single => 'This field appears once.',
    Double => [ 'This field appears', 'two times.' ],
    Triple => [ 'This field appears', 'three', 'times.' ],
  },
  'TestInputMixed successful');

is($ami->error, undef, 'TestInputMixed did not set error');

is_deeply(\@events, [], 'no events during TestInputMixed');
@events = ();

is(socket_output,
   "ActionID: 6\r\nAction: TestInputMixed\r\n\r\n",
   'TestInputMixed output correct');

#.....................................................................
ok($ami->disconnect, 'disconnected');

is($ami->error, undef, 'disconnect did not set error');

is_deeply(\@events, [], 'no events from disconnect');
@events = ();

is(socket_output,
   "ActionID: 7\r\nAction: Logoff\r\n\r\n",
   'disconnect output correct');

done_testing;
