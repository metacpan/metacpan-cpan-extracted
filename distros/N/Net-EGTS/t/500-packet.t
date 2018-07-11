#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 3;

BEGIN {
    use_ok 'Net::EGTS::Packet';
    use_ok 'Net::EGTS::Codes';
}

subtest 'base' => sub {
    plan tests => 16;

    my $packet = Net::EGTS::Packet->new(
        PT  => EGTS_PT_RESPONSE,
    );
    isa_ok $packet, 'Net::EGTS::Packet';

    my $bin = $packet->encode;
    ok $bin, 'encode';
    note $packet->as_debug;

#    my $result = Net::EGTS::Packet->new( $bin );
#    isa_ok $result, 'Net::EGTS::Packet';
#    note $result->as_debug;

    my $result2 = Net::EGTS::Packet->new->decode( \$bin );
    isa_ok $result2, 'Net::EGTS::Packet';
    note $result2->as_debug;

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
    is $packet->PT,  EGTS_PT_RESPONSE, 'Packet Type';
    is $packet->HCS, 20, 'Header Check Sum';
};
