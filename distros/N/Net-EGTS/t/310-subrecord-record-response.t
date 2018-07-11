#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 3;

BEGIN {
    use_ok 'Net::EGTS::SubRecord::Auth::RecordResponse';
    use_ok 'Net::EGTS::Codes';
}

subtest 'base' => sub {
    plan tests => 7;

    my $subrecord = Net::EGTS::SubRecord::Auth::RecordResponse->new(
        RST => EGTS_PC_OK,
    );
    isa_ok $subrecord, 'Net::EGTS::SubRecord::Auth::RecordResponse';

    my $bin = $subrecord->encode;
    ok $bin, 'encode';
    note $subrecord->as_debug;

    my $result = Net::EGTS::SubRecord::Auth::RecordResponse->new( $bin );
    isa_ok $result, 'Net::EGTS::SubRecord::Auth::RecordResponse';
    note $result->as_debug;

    my $result2 = Net::EGTS::SubRecord::Auth::RecordResponse->new->decode( \$bin );
    isa_ok $result2, 'Net::EGTS::SubRecord::Auth::RecordResponse';
    note $result2->as_debug;

    is $subrecord->SRT, EGTS_SR_RECORD_RESPONSE, 'Subrecord Туре';
    is $subrecord->SRL, 3, 'Subrecord Length';

    is $subrecord->RST, EGTS_PC_OK, 'Record Status';
};
