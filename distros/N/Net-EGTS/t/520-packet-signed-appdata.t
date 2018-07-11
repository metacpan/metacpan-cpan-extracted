#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 3;

BEGIN {
    use_ok 'Net::EGTS::Packet::SignedAppdata';
    use_ok 'Net::EGTS::Codes';
}

subtest 'base' => sub {
    plan tests => 19;

    my $packet = Net::EGTS::Packet::SignedAppdata->new;
    isa_ok $packet, 'Net::EGTS::Packet::SignedAppdata';

    my $bin = $packet->encode;
    ok $bin, 'encode';

    my $result = Net::EGTS::Packet::SignedAppdata->new->decode( \$bin );
    isa_ok $result, 'Net::EGTS::Packet::SignedAppdata';

    note $packet->as_debug;

    is $packet->PRV, 1, 'Protocol Version';
    is $packet->SKID, 0, 'Security Key ID';

    is $packet->PRF, 0, 'Prefix';
    is $packet->RTE, 0, 'Route';
    is $packet->ENA, 0, 'Encryption Algorithm';
    is $packet->CMP, 0, 'Compressed';
    is $packet->PRIORITY,  0, 'Priority';

    is $packet->HL,  11, 'Header Length';
    is $packet->HE,  0, 'Header Encoding';
    is $packet->FDL, 2, 'Frame Data Length';
    is $packet->PID, 0, 'Packet Identifier';
    is $packet->PT,  EGTS_PT_SIGNED_APPDATA, 'Packet Type';
    is $packet->HCS, 225, 'Header Check Sum';

    is $packet->SIGL,   0,     'Signature Length';
    is $packet->SIGD,   undef, 'Signature Data';
    is $packet->SDR,    undef, 'Service Data Record';
};
