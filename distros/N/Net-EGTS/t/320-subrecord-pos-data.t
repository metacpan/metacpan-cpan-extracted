#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 4;

BEGIN {
    use_ok 'Net::EGTS::SubRecord::Teledata::PosData';
    use_ok 'Net::EGTS::Codes';

    use_ok 'POSIX', 'strftime';
}

subtest 'base' => sub {
    plan tests => 27;

    my $now = time;
    my $str = strftime '%F %T +0000', gmtime $now;

    my $subrecord = Net::EGTS::SubRecord::Teledata::PosData->new(
        longitude   => 37.7,
        latitude    => 55.6,
        avg_speed   => 53,
        direction   => 270,
        time        => $str,
        dist        => 444,

        order       => 1,

    );
    isa_ok $subrecord, 'Net::EGTS::SubRecord::Teledata::PosData';

    my $bin = $subrecord->encode;
    ok $bin, 'encode';
    note $subrecord->as_debug;

    my $result = Net::EGTS::SubRecord::Teledata::PosData->new( $bin );
    isa_ok $result, 'Net::EGTS::SubRecord::Teledata::PosData';
    note $result->as_debug;

    my $result2 = Net::EGTS::SubRecord::Teledata::PosData->new->decode( \$bin );
    isa_ok $result2, 'Net::EGTS::SubRecord::Teledata::PosData';
    note $result2->as_debug;

    is $subrecord->SRT, EGTS_SR_POS_DATA, 'Subrecord Туре';
    is $subrecord->SRL, 21, 'Subrecord Length';

    is $subrecord->NTM, $now - 1262304000, 'Navigation Time';
    is $subrecord->LAT, 2653335351, 'Latitude';
    is $subrecord->LONG, 899557039, 'Longitude';

    is $subrecord->ALTE,    0, 'altitude exists';
    is $subrecord->LOHS,    0, 'east/west';
    is $subrecord->LAHS,    0, 'south/nord';
    is $subrecord->MV,      1, 'move';
    is $subrecord->BB,      0, 'from storage';
    is $subrecord->CS,      0, 'coordinate system';
    is $subrecord->FIX,     1, '2d/3d';
    is $subrecord->VLD,     1, 'valid';

    is $subrecord->SPD_LO,  18,     'Speed (lower bits)';
    is $subrecord->DIRH,    0x1,    'Direction the Highest bit';
    is $subrecord->ALTS,    0x0,    'Altitude Sign';
    is $subrecord->SPD_HI,  2,      'Speed (highest bits)';

    is $subrecord->DIR,  14,                'Direction';
    is $subrecord->ODM,  4440,              'Odometer';
    is $subrecord->DIN,  128,               'Digital Inputs';
    is $subrecord->SRC,  EGTS_SRCD_TIMER,   'Source';

    is $subrecord->ALT,  undef, 'Altitude';
    is $subrecord->SRCD, undef, 'Source Data';

};
