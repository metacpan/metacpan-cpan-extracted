#!/usr/bin/perl

use 5.010;

use strict;
use warnings;
no  warnings 'syntax';

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

my @sequences = qw [A000045];

BEGIN {
    use_ok ('OEIS') or
        BAIL_OUT ("Loading of 'OEIS' failed");
}

foreach my $sequence (@sequences) {
    use_ok ("OEIS::$sequence");
}

ok defined $OEIS::VERSION, "VERSION is set";

foreach my $sequence (@sequences) {
    my $version = "OEIS::${sequence}::VERSION";
    no strict 'refs';
    ok defined $$version, "$version is set";
}

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
