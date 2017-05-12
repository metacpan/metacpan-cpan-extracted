#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use Test::More;

BEGIN {
    require_ok('Positron::Expression');
}

diag( "Testing Positron::Expression $Positron::Expression::VERSION, Perl $], $^X" );

for my $sub (qw(
    evaluate
)) {
    can_ok('Positron::Expression', $sub);
}

done_testing();
