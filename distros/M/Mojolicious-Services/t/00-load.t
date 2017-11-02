#!perl -T
use 5.010001;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Mojolicious::Services' ) || print "Bail out!\n";
    use_ok( 'Mojolicious::Plugin::Service' ) || print "Bail out!\n";
    use_ok( 'Mojolicious::Service' ) || print "Bail out!\n";
}

diag( "Testing Mojolicious::Services $Mojolicious::Services::VERSION, Perl $], $^X" );
