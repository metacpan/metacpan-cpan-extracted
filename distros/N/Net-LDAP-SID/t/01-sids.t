#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 18;

use Net::LDAP::SID;

my %sids = (
    'S-1-285952273-653124832-513' =>
        '01/02/00/00/11/0b/49/11/e0/e4/ed/26/01/02/00/00',
    'S-1-5-21-2127521184-1604012920-1887927527-72713' =>
        '01/05/00/00/00/00/00/05/15/00/00/00/A0/65/CF/7E/78/4B/9B/5F/E7/7C/87/70/09/1C/01/00',
    'S-1-2-3-4-5-6-1234' =>
        '01/05/00/00/00/00/00/02/03/00/00/00/04/00/00/00/05/00/00/00/06/00/00/00/d2/04/00/00'
);

for my $sid_string ( keys %sids ) {
    compare_string_and_binary( $sid_string, $sids{$sid_string} );
}

sub compare_string_and_binary {
    my ( $sid_string, $sid_hex_string ) = @_;

    my $sid_binary = pack '(H2)*', split( /\//, $sid_hex_string );

    diag("str      = $sid_string");
    diag( "bin      = " . join( '\\', unpack '(H2)*', $sid_binary ) );

    eval {
        ok( my $sid_from_string = Net::LDAP::SID->new($sid_string),
            "new SID" );
        is( $sid_from_string->as_string, $sid_string, "->as_string" );
        is( $sid_from_string->as_binary, $sid_binary, "->as_binary" );

        ok( my $sid_from_binary = Net::LDAP::SID->new($sid_binary),
            "new SID" );
        is( $sid_from_binary->as_string, $sid_string, "->as_string" );
        is( $sid_from_binary->as_binary, $sid_binary, "->as_binary" );
    };
    warn $@ if $@;
}
