#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 3;

BEGIN {
    use_ok 'Net::EGTS::SubRecord::Auth::ResultCode';
    use_ok 'Net::EGTS::Codes';
}

subtest 'base' => sub {
    plan tests => 7;

    my $subrecord = Net::EGTS::SubRecord::Auth::ResultCode->new(
        RCD => EGTS_PC_OK,
    );
    isa_ok $subrecord, 'Net::EGTS::SubRecord::Auth::ResultCode';

    my $bin = $subrecord->encode;
    ok $bin, 'encode';
    note $subrecord->as_debug;

    my $result = Net::EGTS::SubRecord::Auth::ResultCode->new( $bin );
    isa_ok $result, 'Net::EGTS::SubRecord::Auth::ResultCode';
    note $result->as_debug;

    my $result2 = Net::EGTS::SubRecord::Auth::ResultCode->new->decode( \$bin );
    isa_ok $result2, 'Net::EGTS::SubRecord::Auth::ResultCode';
    note $result2->as_debug;

    is $subrecord->SRT, EGTS_SR_RESULT_CODE, 'Subrecord Туре';
    is $subrecord->SRL, 1, 'Subrecord Length';

    is $subrecord->RCD, EGTS_PC_OK, 'Result Code';
};
