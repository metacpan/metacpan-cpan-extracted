#!/usr/bin/perl

use strict;
use Test::More tests => 4;

use Socket::Packet qw( siocgstamp );

use IO::Socket::INET;
use POSIX qw( EINVAL ENOENT ENOTTY );

# Without actually running as root and capturing a packet we can't really
# obtain a valid timestamp. But we can at least check the function exists and
# that it has some error conditions

# Pipes definitely shouldn't have last packet timestamps

pipe( my $p1, my $p2 ) or die "Cannot pipe() - $!";

my $stamp; my $errno;

$stamp = siocgstamp( $p1 ); $errno = $!+0;
is( $stamp, undef, 'siocgstamp(STDIN) fails' );
# Systems vary - sometimes we get EINVAL, sometimes we get ENOTTY
ok( $errno == EINVAL || $errno == ENOTTY, 'siocgstamp(STDIN) errors EINVAL or ENOTTY' )
   or diag( sprintf "  Expected %d or %d; got %d", EINVAL, ENOTTY, $errno );

my $sock = IO::Socket::INET->new( LocalPort => 0 );

$stamp = siocgstamp( $sock ); $errno = $!+0;
is( $stamp, undef, 'siocgstamp($sock) fails' );
is( $errno, ENOENT, 'siocgstamp($sock) errors ENOENT' );
