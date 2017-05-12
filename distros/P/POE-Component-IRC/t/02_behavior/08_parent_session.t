# This tests the following from IRC.pm's pod:
#
# Starting with version 4.96, if you spawn the component from inside another
# POE session, the component will automatically register that session as
# wanting 'all' irc events. That session will receive an irc_registered
# event indicating that the component is up and ready to go.

use strict;
use warnings FATAL => 'all';
use POE;
use POE::Component::IRC;
use Test::More tests => 2;

POE::Session->create(
    package_states => [
        main => [qw(_start irc_registered)],
    ],
);

$poe_kernel->run();

sub _start {
    my ($heap) = $_[HEAP];
    $heap->{irc} = POE::Component::IRC->spawn();
}

sub irc_registered {
    my ($heap, $irc) = @_[HEAP, ARG0];
    pass('Child registered us');
    isa_ok($irc, 'POE::Component::IRC');
    $irc->yield('shutdown');
}

