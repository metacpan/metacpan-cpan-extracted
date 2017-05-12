#!perl

package Foo;

use Test::More tests => 7;

use POE;
use base 'POE::Session::AttributeBased';

sub _start : State {
    my $k : KERNEL;
    my $h : HEAP;

    ok( 1, "in _start" );

    $k->yield( tick => 5 );
}

sub tick : State {
    my $k     : KERNEL;
    my $count : ARG0;

    ok( 1, "in tick" );
    return 0 unless $count;

    $k->yield( tick => $count - 1 );
    return 1;
}

POE::Session->create(
    Foo->inline_states(),
);

POE::Kernel->run();
exit;
