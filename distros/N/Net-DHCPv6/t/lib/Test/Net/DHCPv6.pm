#!/bin/false
# ABSTRACT: Test helper for Net::DHCPv6 -- hex fixtures and common checks
# PODNAME: Test::Net::DHCPv6
use strictures 2;

package Test::Net::DHCPv6;

use Carp     ();
use Exporter qw(import);

our @EXPORT_OK = qw(
    hex2bytes
    bytes2hex
    solicit_hex
    advertise_hex
    request_hex
    reply_hex
);

sub hex2bytes {
    my ( $hex ) = @_;
    $hex =~ s/[ \t\n\r]+//g;
    Carp::croak 'Odd hex string length' if CORE::length( $hex ) % 2;
    return pack( 'H*', $hex );
}

sub bytes2hex {
    my ( $bytes ) = @_;
    return unpack( 'H*', $bytes );
}

sub solicit_hex {
    return '01 01e240 0001 000e 0001 0001 0001e240 001122334455';
}

sub advertise_hex {
    return '02 02c8b0 0002 000e 0001 0001 000f423f aabbccddeeff';
}

sub request_hex {
    return
          '03 03d090 0001 000e 0001 0001 0001e240 001122334455'
        . ' 0002 000e 0001 0001 000f423f aabbccddeeff'
        . ' 0006 0004 0017 0018';
}

sub reply_hex {
    return '07 04cbcf 0003 0028 0000002a 00000e10 00001518'
        . ' 00050018 20010db8000000000000000000000001 00001c20 00015180';
}

1;
