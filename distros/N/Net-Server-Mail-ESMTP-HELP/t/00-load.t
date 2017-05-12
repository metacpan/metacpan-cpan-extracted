#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::Server::Mail::ESMTP::HELP' ) || print "Bail out!
";
}

diag( "Testing Net::Server::Mail::ESMTP::HELP $Net::Server::Mail::ESMTP::HELP::VERSION, Perl $], $^X" );
