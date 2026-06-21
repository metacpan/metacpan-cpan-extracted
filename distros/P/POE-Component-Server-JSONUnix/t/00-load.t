#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'POE::Component::Server::JSONUnix' ) || print "Bail out!\n";
}

diag( "Testing POE::Component::Server::JSONUnix $POE::Component::Server::JSONUnix::VERSION, Perl $], $^X" );
