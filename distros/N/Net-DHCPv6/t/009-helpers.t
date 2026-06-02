#!/usr/bin/env perl
use strictures 2;
use Test2::Tools::Exception qw( dies lives );
use Test2::V1 -ipP, qw(is ok done_testing);            ## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)

use lib 't/lib';
use lib 'lib';

use Socket qw( AF_INET6 inet_pton inet_ntop );

use Net::DHCPv6::Helpers;

my $class  = 'Net::DHCPv6::Helpers';
my $loop   = inet_pton( AF_INET6, '::1' );
my $ll     = inet_pton( AF_INET6, 'fe80::1' );
my $global = inet_pton( AF_INET6, '2001:db8::1' );

# _resolve_ipv6

ok( !defined $class->_resolve_ipv6( undef ), '_resolve_ipv6: undef returns undef' );

ok( dies { $class->_resolve_ipv6( q() ) }, '_resolve_ipv6: empty string dies' );

is( $class->_resolve_ipv6( $loop ), $loop, '_resolve_ipv6: 16-byte wire format pass-through' );

my $wire_with_colon_byte = pack( 'C*', ( 0x3A, ( 0x00 ) x 15 ) );
is( $class->_resolve_ipv6( $wire_with_colon_byte ),
    $wire_with_colon_byte, '_resolve_ipv6: 16-byte wire with 0x3A byte pass-through' );

is( $class->_resolve_ipv6( $ll ),     $ll,     '_resolve_ipv6: link-local wire pass-through' );
is( $class->_resolve_ipv6( $global ), $global, '_resolve_ipv6: global wire pass-through' );

is( $class->_resolve_ipv6( '::1' ),         $loop,   '_resolve_ipv6: text ::1' );
is( $class->_resolve_ipv6( 'fe80::1' ),     $ll,     '_resolve_ipv6: text fe80::1' );
is( $class->_resolve_ipv6( '2001:db8::1' ), $global, '_resolve_ipv6: text 2001:db8::1' );

ok( dies { $class->_resolve_ipv6( 'short' ) }, '_resolve_ipv6: non-16-byte without colon dies' );

ok( dies { $class->_resolve_ipv6( 'not:an:ip' ) }, '_resolve_ipv6: invalid text with colons dies' );

# 16-char IPv6 text address — looks like text, should be parsed
my $sixteen_char_text = 'aa:b:c:d:e:f:1:2';
my $sixteen_char_wire = inet_pton( AF_INET6, $sixteen_char_text );
is( $class->_resolve_ipv6( $sixteen_char_text ),
    $sixteen_char_wire, '_resolve_ipv6: 16-char text address parsed via inet_pton' );

# _format_ipv6

ok( !defined $class->_format_ipv6( undef ), '_format_ipv6: undef returns undef' );
is( $class->_format_ipv6( $loop ),   '::1',         '_format_ipv6: loopback' );
is( $class->_format_ipv6( $ll ),     'fe80::1',     '_format_ipv6: link-local' );
is( $class->_format_ipv6( $global ), '2001:db8::1', '_format_ipv6: global' );

# _pick_addr

ok( !defined $class->_pick_addr( {}, 'addr' ), '_pick_addr: missing field returns undef' );

is( $class->_pick_addr( { addr_raw => $loop }, 'addr' ), $loop, '_pick_addr: raw field returned directly' );

is( $class->_pick_addr( { addr => '::1' }, 'addr' ), $loop, '_pick_addr: text field resolved' );

ok( dies { $class->_pick_addr( { addr => 'bogus' }, 'addr' ) }, '_pick_addr: invalid text dies' );

# _pick_addrs

ok( !defined $class->_pick_addrs( {}, 'servers' ), '_pick_addrs: missing field returns undef' );

is(
    $class->_pick_addrs( { servers_raw => [ $loop, $ll ] }, 'servers' ),
    [ $loop, $ll ],
    '_pick_addrs: raw arrayref returned directly'
);

is(
    $class->_pick_addrs( { servers => [ '::1', 'fe80::1' ] }, 'servers' ),
    [ $loop, $ll ],
    '_pick_addrs: arrayref of text resolved'
);

is( $class->_pick_addrs( { servers => '::1' }, 'servers' ), [$loop], '_pick_addrs: scalar text wrapped in arrayref' );

ok( dies { $class->_pick_addrs( { servers => 'bogus' }, 'servers' ) }, '_pick_addrs: invalid scalar dies' );

done_testing();
