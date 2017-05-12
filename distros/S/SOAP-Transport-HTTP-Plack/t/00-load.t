#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'SOAP::Transport::HTTP::Plack' ) || print "Bail out!\n";
    use_ok( 'XMLRPC::Transport::HTTP::Plack' ) || print "Bail out!\n";
}

diag( "Testing SOAP::Transport::HTTP::Plack $SOAP::Transport::HTTP::Plack::VERSION, Perl $], $^X" );
