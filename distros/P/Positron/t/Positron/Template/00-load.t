#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use Test::More;

BEGIN {
    require_ok('Positron::Template');
}

if(defined($Positron::Template::VERSION)) {
    diag( "Testing Positron::Template $Positron::Template::VERSION, Perl $], $^X" );
}

for my $sub (qw(
    new
    process
    add_include_paths
)) {
    can_ok('Positron::Template', $sub);
}

done_testing();
