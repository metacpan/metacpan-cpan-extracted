#!/usr/bin/perl
use strict; use warnings;

use Test::More tests=>4;

use Sub::Curried;

curry empty_sig () {
    return "EMPTY";
}
curry no_sig {
    return "NO_SIG";
}

isa_ok (\&empty_sig, 'Sub::Curried');
isa_ok (\&no_sig,    'Sub::Curried');

my $n1 = empty_sig();
is $n1, 'EMPTY', "No-arg curried sub executes on... no args";

my $n2 = no_sig();
is $n2, 'NO_SIG', "No-arg curried sub executes on... no args";
