#!perl -w
use strict;
use Test::Requires { 'Test::LeakTrace' => 0.13 };
use Test::More;

use POSIX::pselect;

no_leaks_ok {
    my $a = '';
    my $b = '';
    my $c = '';
    pselect($a, $b, $c, 0, [qw(INT HUP)]);
};

done_testing;
