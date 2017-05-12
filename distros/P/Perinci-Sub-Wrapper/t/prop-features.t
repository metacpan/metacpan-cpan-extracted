#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;
use Test::Perinci::Sub::Wrapper qw(test_wrap);

my $sub  = sub {[200,"OK"]};
my $meta = {v=>1.1, features=>{tx=>{req=>1}}};
{
    test_wrap(
        name => 'deps 1',
        wrap_args => {sub => $sub, meta => $meta},
        wrap_status => 200,
        call_argsr => [],
        call_status => 412,
    );
    test_wrap(
        name => 'deps 1',
        wrap_args => {sub => $sub, meta => $meta},
        wrap_status => 200,
        call_argsr => [-tx_manager=>"dummy"],
        call_status => 200,
    );

    # XXX test under trap=0
}

done_testing;
