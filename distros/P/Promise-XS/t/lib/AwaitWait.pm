package AwaitWait;

use Test::More;

use Promise::XS;

sub test_success {
    my $d = Promise::XS::deferred();

    my @timer_state = shift->($d);

    my @got = $d->promise()->AWAIT_WAIT();

    is( "@got", "42 34", 'top-level await: success' );

    return;
}

1;
