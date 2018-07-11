#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 4;

BEGIN {
    use_ok 'Net::EGTS::Packet';
    use_ok 'Net::EGTS::Packet::Response';
    use_ok 'Net::EGTS::Codes';
}

subtest 'rebless packet on decode' => sub {
    plan tests => 6;

    my $packet = Net::EGTS::Packet::Response->new(
        RPID    => 1,
        PR      => EGTS_PC_OK,
    );
    isa_ok $packet, 'Net::EGTS::Packet::Response';

    my $bin = $packet->encode;
    ok $bin, 'encode';

    my $result = Net::EGTS::Packet::Response->new->decode( \$bin );
    isa_ok $result, 'Net::EGTS::Packet::Response';

    is $packet->RPID,   1,          'Response Packet ID';
    is $packet->PR,     EGTS_PC_OK, 'Processing Result';
    is $packet->SDR,    undef,      'Service Data Record';
};
