#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;
use Test::NoWarnings;
use POE::Declare::HTTP::Server ();

# Create the server
my $server = POE::Declare::HTTP::Server->new(
	Hostname => '127.0.0.1',
	Port     => '8010',
	Handler  => sub { },
);
isa_ok( $server, 'POE::Declare::HTTP::Server' );
is( $server->Hostname, '127.0.0.1', '->Hostname ok' );
is( $server->Port,     '8010',      '->Port ok'     );
is( ref($server->Handler), 'CODE',  '->Handler ok'  );
