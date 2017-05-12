#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Plack::Debugger::Panel::DBIProfile' ) || print "Bail out!\n";
}

diag( "Testing Plack::Debugger::Panel::DBIProfile $Plack::Debugger::Panel::DBIProfile::VERSION, Perl $], $^X" );
