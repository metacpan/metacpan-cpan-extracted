use Test::More 0.88;
use strict; use warnings FATAL => 'all';

use POE;
use POEx::IRC::Backend;

use IRC::Toolkit::CTCP;
use IRC::Mode::Set;

use_ok( 'POEx::IRC::Client::Lite' );

my $got = {};
my $expected = {
  'client connected'        => 1,
  'client sent USER'        => 1,
  'client sent NICK'        => 1,
  'client NICK looks ok'    => 1,
  'client got SNACK'        => 1,
  'client got public_msg'   => 1,
  'client got ctcp_version' => 1,
  'client sent arbitrary'   => 1,
  'client sent QUIT'        => 1,
  'client sent correct MODE' => 2,
};

alarm 60;
POE::Session->create(
  package_states => [
    main => [ qw/ 
      _start
      check
      shutdown

      ircsock_registered
      ircsock_listener_created
      ircsock_listener_open
      ircsock_input

      client_irc_snack
      client_irc_public_msg
      client_irc_ctcp_version

      send_quit
    / ],
  ],
);
$poe_kernel->run;

sub _start {
  my ($k, $heap) = @_[KERNEL, HEAP];

  $k->sig(ALRM => shutdown => 'timeout');

  $heap->{serv} = POEx::IRC::Backend->new->spawn;
  $k->post( $heap->{serv}->session_id, 'register' );

  $k->delay( check => 0.5 );
}

sub check {
  my ($k, $heap) = @_[KERNEL, HEAP];

  if (keys %$got == keys %$expected) {
    $k->yield( 'shutdown' );
    return
  }

  $k->delay( check => 0.5 );
}

sub shutdown {
  my ($k, $heap) = @_[KERNEL, HEAP];

  $k->alarm_remove_all;

  $heap->{serv}->shutdown;
  $heap->{client}->stop;

  fail "Timed out" if $_[ARG0];
}


### "server" bits ->

sub ircsock_registered {
  my ($k, $heap) = @_[KERNEL, HEAP];
  my $backend = $_[ARG0];

  pass("ircsock_registered");

  $backend->create_listener(
    bindaddr => '127.0.0.1',
    port     => 0,
  );
}

sub ircsock_listener_created {
  my ($k, $heap) = @_[KERNEL, HEAP];
  my $listener = $_[ARG0];

  pass("Got listener_created");
  note("Starting client");

  $heap->{client} = POEx::IRC::Client::Lite->new(
    event_prefix => 'client_',
    server => $listener->addr,
    port   => $listener->port,
    nick   => 'test',
    username => 'user',
  );

  ok $poe_kernel->alias_resolve($heap->{client}->session_id),
    'session_id set after new ok';

  $heap->{client}->connect;
}

sub ircsock_listener_open {
  my ($k, $heap)        = @_[KERNEL, HEAP];
  my ($conn, $listener) = @_[ARG0, ARG1];

  $got->{'client connected'}++;

  ## Fire some traffic at the client.
  $heap->{serv}->send(
    {
      prefix  => 'server',
      command => 'snack',
      params  => [ 'things and stuff' ],
    },
    $conn->wheel_id
  );

  $heap->{serv}->send(
    {
      prefix  => 'server',
      command => 'privmsg',
      params  => [ '#chan', 'some message' ],
    },
    $conn->wheel_id
  );

  $heap->{serv}->send(
    {
      prefix  => 'server',
      command => 'privmsg',
      params  => [ 'test', ctcp_quote('VERSION') ]
    },
    $conn->wheel_id
  );

}

sub ircsock_input {
  my ($k, $heap)  = @_[KERNEL, HEAP];
  my ($conn, $ev) = @_[ARG0, ARG1];
  
  if ($ev->command eq 'USER') {
    $got->{'client sent USER'}++
  }

  if ($ev->command eq 'NICK') {
    $got->{'client sent NICK'}++;
    $got->{'client NICK looks ok'}++
      if $ev->params->[0] eq 'test';
  }

  if ($ev->command eq 'NONSENSE') {
    $got->{'client sent arbitrary'}++;
  }

  if ($ev->command eq 'QUIT') {
    $got->{'client sent QUIT'}++;
  }

  if ($ev->command eq 'MODE') {
    $got->{'client sent correct MODE'}++
      if  $ev->params->[0] eq '#target'
      and $ev->params->[1] eq '+o-o avenj avenj';
  }
}


### our client's events -> 

## An arbitrary command:
sub client_irc_snack {
  my ($k, $heap) = @_[KERNEL, HEAP];
  my $ev = $_[ARG0];

  $got->{'client got SNACK'}++;

  $heap->{client}->send(
    {
      command => 'nonsense',
    }
  );

  ## IRC::Mode::Set
  $heap->{client}->mode(
    '#target',
    IRC::Mode::Set->new(
      mode_string => '+o-o avenj avenj',
    )
  );

  ## Stringy mode
  $heap->{client}->mode(
    '#target',
    '+o-o avenj avenj'
  );
}

## pubmsg parser:
sub client_irc_public_msg {
  my ($k, $heap) = @_[KERNEL, HEAP];
  my $ev = $_[ARG0];

  $got->{'client got public_msg'}++;
}

## ctcp parser:
sub client_irc_ctcp_version {
  my ($k, $heap) = @_[KERNEL, HEAP];
  my $ev = $_[ARG0];

  $got->{'client got ctcp_version'}++;
  $k->delay( 'send_quit' => 1 );
}

sub send_quit {
  my ($k, $heap) = @_[KERNEL, HEAP];
  $heap->{client}->disconnect('bye');
}


for my $t (keys %$expected) {
  ok( defined $got->{$t}, "have result for '$t'" );
  cmp_ok( $got->{$t}, '==', $expected->{$t},
    "result for '$t' looks ok"
  );
}

unless (keys %$expected == keys %$got) {
  diag explain $got
}

done_testing;
