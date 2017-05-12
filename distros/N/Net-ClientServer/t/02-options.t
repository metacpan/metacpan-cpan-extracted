#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most 'no_plan';

use Net::ClientServer;

my ( $platform );

$platform = Net::ClientServer->new( port => 1 );
is( $platform->pidfile, undef );
is( $platform->stderr, undef );

$platform = Net::ClientServer->new( port => 1, name => 't-platform' );
like( $platform->pidfile, qr/t-platform/ );
like( $platform->stderr, qr/t-platform/ );

$platform = Net::ClientServer->new( port => 1, home => 't-platform' );
like( $platform->pidfile, qr/t-platform/ );
like( $platform->stderr, qr/t-platform/ );

$platform = Net::ClientServer->new( port => 1, home => 't-platform', pidfile => 0 );
is( $platform->pidfile, undef );
like( $platform->stderr, qr/t-platform/ );

$platform = Net::ClientServer->new( port => 1, home => 't-platform', stderr => 0 );
like( $platform->pidfile, qr/t-platform/ );
is( $platform->stderr, undef );

$platform = Net::ClientServer->new( port => 1, home => 1 );
like( $platform->pidfile, qr/net-client-server-1/ );
like( $platform->stderr, qr/net-client-server-1/ );
