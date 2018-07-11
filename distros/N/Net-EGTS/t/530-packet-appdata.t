#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 3;

BEGIN {
    use_ok 'Net::EGTS::Packet::Appdata';
    use_ok 'Net::EGTS::Codes';
}

subtest 'base' => sub {
    plan tests => 17;

    my $packet = Net::EGTS::Packet::Appdata->new;
    isa_ok $packet, 'Net::EGTS::Packet::Appdata';

    my $bin = $packet->encode;
    ok $bin, 'encode';

    my $result = Net::EGTS::Packet::Appdata->new->decode( \$bin );
    isa_ok $result, 'Net::EGTS::Packet::Appdata';

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
    is $packet->FDL, 0, 'Frame Data Length';
    is $packet->PID, 0, 'Packet Identifier';
    is $packet->PT,  EGTS_PT_APPDATA, 'Packet Type';
    is $packet->HCS, 37, 'Header Check Sum';

    is $packet->SDR,    undef, 'Service Data Record';
};
