use strict;
use warnings FATAL => 'all';
use POE;
use POE::Component::IRC;
use Socket qw(unpack_sockaddr_in);
use Test::More tests => 4;

my $bot = POE::Component::IRC->spawn();

POE::Session->create(
    package_states => [
        main => [qw(
            _start
            irc_registered
            irc_delay_set
            irc_delay_removed
        )],
    ],
);

$poe_kernel->run();

sub _start {
    $bot->yield(register => 'all');
}

sub irc_registered {
  my ($heap, $irc) = @_[HEAP, ARG0];

  $heap->{alarm_id} =
    $irc->delay( [ connect => {
        nick    => 'TestBot',
        server  => '127.0.0.1',
        port    => 6667,
    } ], 25 );

    ok($heap->{alarm_id}, 'Set alarm');
}

sub irc_delay_set {
    my ($heap, $event, $alarm_id) = @_[HEAP, STATE, ARG0];

    is($alarm_id, $heap->{alarm_id}, $_[STATE]);
    my $opts = $bot->delay_remove($alarm_id);
    ok($opts, 'Delay Removed');
}

sub irc_delay_removed {
    my ($heap, $alarm_id) = @_[HEAP, ARG0];

    is($alarm_id, $heap->{alarm_id}, $_[STATE] );
    $bot->yield('shutdown');
}

