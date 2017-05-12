#!/usr/bin/perl -T

use Test::More tests => 3;
use Paranoid;
use Paranoid::Network::Socket qw(:all);

psecureEnv();

use strict;
use warnings;

my $rv;

# Test for import of sockaddr_in
ok( ( defined *main::sockaddr_in{CODE} ), 'sockaddr_in 1' );

# Test for output of has_ipv6 matching presence of sockaddr_in6
if ( has_ipv6() ) {
    ok( ( defined *main::sockaddr_in6{CODE} ), 'sockaddr_in6 1y' );
} else {
    ok( ( !defined *main::sockaddr_in6{CODE} ), 'sockaddr_in6 1n' );
}

# Test for import of CRLF
is( CRLF, "\015\012", "CRLF 1" );

