#!/usr/bin/perl -T

use Test::More tests => 32;
use Paranoid;
use Paranoid::Debug;
use Paranoid::Network::IPv4 qw(:all);
use Paranoid::Network::Socket;

#PDEBUG = 20;

psecureEnv();

use strict;
use warnings;

my ( @net, $rv );

# Test 192.168.0.0/24 conversion
@net = ipv4NetConvert('192.168.0.0/24');
is( scalar(@net), 3, 'convert 192.168.0.0/24 1' );
is( inet_ntoa( pack 'N', $net[0] ),
    '192.168.0.0', 'convert 192.168.0.0/24 2' );
is( inet_ntoa( pack 'N', $net[1] ),
    '192.168.0.255', 'convert 192.168.0.0/24 3' );
is( inet_ntoa( pack 'N', $net[2] ),
    '255.255.255.0', 'convert 192.168.0.0/24 4' );

# Test 192.168.0.64/28 conversion
@net = ipv4NetConvert('192.168.0.64/28');
is( scalar(@net), 3, 'convert 192.168.0.64/28 1' );
is( inet_ntoa( pack 'N', $net[0] ),
    '192.168.0.64', 'convert 192.168.0.64/28 2' );
is( inet_ntoa( pack 'N', $net[1] ),
    '192.168.0.79', 'convert 192.168.0.64/28 3' );
is( inet_ntoa( pack 'N', $net[2] ),
    '255.255.255.240', 'convert 192.168.0.64/28 4' );

# Test 192.168.1.0/255.255.255.248 conversion
@net = ipv4NetConvert('192.168.1.0/255.255.255.248');
is( scalar(@net), 3, 'convert 192.168.1.0/255.255.255.248 1' );
is( inet_ntoa( pack 'N', $net[0] ),
    '192.168.1.0', 'convert 192.168.1.0/255.255.255.248 2' );
is( inet_ntoa( pack 'N', $net[1] ),
    '192.168.1.7', 'convert 192.168.1.0/255.255.255.248 3' );
is( inet_ntoa( pack 'N', $net[2] ),
    '255.255.255.248', 'convert 192.168.1.0/255.255.255.248 4' );

# Test foo & undef
@net = ipv4NetConvert('foo');
is( scalar(@net), 0, 'convert foo 1' );
@net = ipv4NetConvert(undef);
is( scalar(@net), 0, 'convert undef 1' );

# Test intersection of 192.168.0.0/24 and 192.168.0.128/25
is( ipv4NetIntersect(qw(192.168.0.0/24 192.168.0.128/25)),
    1, 'netIntersect 1' );

# Test intersection of 192.168.0.0/24 and 192.168.0.128/25
is( ipv4NetIntersect(qw(192.168.0.128/25 192.168.0.128/24)),
    -1, 'netIntersect 2' );

# Test intersection of 192.168.0.0/24 and 10.0.0.0/8
is( ipv4NetIntersect(qw(192.168.0.0/24 10.0.0.0/8)), 0, 'netIntersect 3' );

# Test intersection of 192.168.0.0/24 and 192.168.0.0/16
is( ipv4NetIntersect(qw(192.168.0.0/24 192.168.0.0/16)),
    -1, 'netIntersect 4' );

# Test intersection of 192.168.0.0/24 and 192.168.0.53
is( ipv4NetIntersect(qw(192.168.0.0/24 192.168.0.53)), 1, 'netIntersect 5' );

# Test intersection of 192.168.0.0/24 and 10.0.0.53
is( ipv4NetIntersect(qw(192.168.0.0/24 10.0.0.53)), 0, 'netIntersect 6' );

# Test intersection of 192.168.0.0/24 and foo
is( ipv4NetIntersect(qw(192.168.0.0/24 foo)), 0, 'netIntersect 7' );

# Test intersection of bar and foo
is( ipv4NetIntersect(qw(bar foo)), 0, 'netIntersect 8' );

# Test intersection of bar and undef
is( ipv4NetIntersect( qw(bar), 'undef' ), 0, 'netIntersect 9' );

# Test str sort
my @nets   = qw( 127.0.0.1 192.168.0.0/16 10.1.25.30 );
my @sorted = sort ipv4StrSort @nets;
is( $sorted[0], '10.1.25.30',     'ipv4StrSort 1' );
is( $sorted[1], '127.0.0.1',      'ipv4StrSort 2' );
is( $sorted[2], '192.168.0.0/16', 'ipv4StrSort 3' );

package foo;
use Test::More;
use Paranoid::Network::Socket;
use Paranoid::Network::IPv4 qw(:all);

# Test packed sort
$nets[1] =~ s#/\d+$##;    #
foreach (@nets) { $_ = inet_aton($_) }
@sorted = sort ipv4PackedSort @nets;
is( $sorted[0], $nets[2], 'ipv4PackedSort 1' );
is( $sorted[1], $nets[0], 'ipv4PackedSort 2' );
is( $sorted[2], $nets[1], 'ipv4PackedSort 3' );

package bar;
use Test::More;
use Paranoid::Network::Socket;
use Paranoid::Network::IPv4 qw(:all);

# Test num sort
foreach (@nets) { $_ = unpack 'N', $_ }
@sorted = sort ipv4NumSort @nets;
is( $sorted[0], $nets[2], 'ipv4NumSort 1' );
is( $sorted[1], $nets[0], 'ipv4NumSort 2' );
is( $sorted[2], $nets[1], 'ipv4NumSort 3' );

