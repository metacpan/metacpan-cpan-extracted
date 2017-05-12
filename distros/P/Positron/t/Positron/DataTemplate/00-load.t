#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use Test::More;

BEGIN {
    require_ok('Positron::DataTemplate');
}

diag( "Testing Positron::DataTemplate $Positron::DataTemplate::VERSION, Perl $], $^X" );

for my $sub (qw(
    new
    process
    add_include_paths
)) {
    can_ok('Positron::DataTemplate', $sub);
}

done_testing();
