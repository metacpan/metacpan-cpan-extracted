#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

my $moodel;

BEGIN {
    $moodel = $ENV{WHICH_MOODEL} || "Moo";
    eval "use $moodel;"; $@ and die $@;
    $moodel->import;
    use_ok('MooX::Cmd') || BAIL_OUT("Couldn't load MooX::Cmd");
}

diag( "Testing MooX::Cmd $MooX::Cmd::VERSION, $moodel " . $moodel->VERSION . ", Perl $], $^X" );

done_testing;
