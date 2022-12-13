#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Terse::Config' ) || print "Bail out!\n";
    use_ok( 'Terse::Plugin::Config' ) || print "Bail out!\n";
    use_ok( 'Terse::Plugin::Config::YAML' ) || print "Bail out!\n";
}

diag( "Testing Terse::Config $Terse::Config::VERSION, Perl $], $^X" );
