#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 4;

BEGIN {
    use_ok 'Net::EGTS::SubRecord';
    use_ok 'Net::EGTS::Codes';
}

subtest 'base' => sub {
    plan tests => 7;

    my $subrecord = Net::EGTS::SubRecord->new(
        SRT => EGTS_SR_RESULT_CODE,
        SRD => EGTS_PC_OK,
    );
    isa_ok $subrecord, 'Net::EGTS::SubRecord';

    my $bin = $subrecord->encode;
    ok $bin, 'encode';
    note $subrecord->as_debug;

    my $result = Net::EGTS::SubRecord->new( $bin );
    isa_ok $result, 'Net::EGTS::SubRecord';
    note $result->as_debug;

    my $result2 = Net::EGTS::SubRecord->new->decode( \$bin );
    isa_ok $result2, 'Net::EGTS::SubRecord';
    note $result2->as_debug;

    is $subrecord->SRT, EGTS_SR_RESULT_CODE, 'Subrecord Туре';
    is $subrecord->SRL, 1, 'Subrecord Length';
    is $subrecord->SRD, EGTS_PC_OK, 'Subrecord Data';
};

subtest 'decode_all' => sub {
    plan tests => 5;

    my $subrecord1 = Net::EGTS::SubRecord->new(
        SRT => EGTS_SR_RESULT_CODE,
        SRD => EGTS_PC_OK,
    );
    isa_ok $subrecord1, 'Net::EGTS::SubRecord';

    my $subrecord2 = Net::EGTS::SubRecord->new(
        SRT => EGTS_SR_RESULT_CODE,
        SRD => EGTS_PC_TEST_FAILED,
    );
    isa_ok $subrecord2, 'Net::EGTS::SubRecord';

    my $bin = join '', map { $_->encode } $subrecord1, $subrecord2;

    my @subrecords = Net::EGTS::SubRecord->decode_all($bin);
    is @subrecords, 2, 'two subrecords';
    is $subrecords[0]->SRD, EGTS_PC_OK,             'SRD 1';
    is $subrecords[1]->SRD, EGTS_PC_TEST_FAILED,    'SRD 2';
}
