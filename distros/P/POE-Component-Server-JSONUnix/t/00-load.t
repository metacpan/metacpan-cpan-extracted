#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'POE::Component::Server::JSONUnix' )                 || print "Bail out!\n";
    use_ok( 'POE::Component::Server::JSONUnix::Client' )         || print "Bail out!\n";
    use_ok( 'POE::Component::Server::JSONUnix::BlockingClient' ) || print "Bail out!\n";
}

diag( "Testing POE::Component::Server::JSONUnix $POE::Component::Server::JSONUnix::VERSION, Perl $], $^X" );
