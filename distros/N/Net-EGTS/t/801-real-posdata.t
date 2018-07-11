#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 7;

BEGIN {
    use_ok 'Net::EGTS::Packet';
    use_ok 'Net::EGTS::Record';
    use_ok 'Net::EGTS::SubRecord::Teledata::PosData';
    use_ok 'Net::EGTS::Util';
    use_ok 'Net::EGTS::Codes';
}

subtest 'send' => sub {
    plan tests => 55;

    my $CAR_ID = 908944;

    my $test = q(
        00000001
        00000000
        00000011
        00001011
        00000000
        00100011 00000000
        00000001 00000000
        00000001
        00000100

        00011000 00000000
        00000001 00000000
        00000001
        10010000 11011110 00001101 00000000
        00000010
        00000010

        00010000
        00010101 00000000

        11001111 00001101 00000010 00010000
        11010111 11101001 10100000 10011110
        00001010 01001100 10010100 00110101
        00000011
        00000000 00000000
        00000000
        00000000 00000000 00000000
        00000000
        00000000

        10100101 00001010
    );
    s{[^01]}{}g, $_ = pack('B*' => $_) for $test;

    my $bin = "$test";
    my $packet = Net::EGTS::Packet->stream( \$bin );
    isa_ok $packet, 'Net::EGTS::Packet::Appdata';

    note $packet->as_debug;

    is $packet->PRV, 1,                 'Protocol Version';
    is $packet->SKID, 0,                'Security Key ID';

    is $packet->PRF, 0,                 'Prefix';
    is $packet->RTE, 0,                 'Route';
    is $packet->ENA, 0,                 'Encryption Algorithm';
    is $packet->CMP, 0,                 'Compressed';
    is $packet->PRIORITY,  3,           'Priority';

    is $packet->HL,  11,                'Header Length';
    is $packet->HE,  0,                 'Header Encoding';
    is $packet->FDL, 35,                'Frame Data Length';
    is $packet->PID, 1,                 'Packet Identifier';
    is $packet->PT,  EGTS_PT_APPDATA,   'Packet Type';
    is $packet->HCS, 4,                 'Header Check Sum';

    is length($packet->SFRD), 35,       'Service Frame Data';
    is $packet->SFRCS, 2725,            'Service Frame Data Check Sum';

    is scalar(@{ $packet->records }), 1, 'one record';

    my $record = $packet->records->[0];
    isa_ok $record, 'Net::EGTS::Record';
    note $record->as_debug;

    is $record->RL, 24,                 'Record Length';
    is $record->RN, 1,                  'Record Number';

    is $record->SSOD, 0,                'Source Service On Device';
    is $record->RSOD, 0,                'Recipient Service On Device';
    is $record->GRP, 0,                 'Group';
    is $record->RPP, 0,                 'Record Processing Priority';
    is $record->TMFE, 0,                'Time Field Exists';
    is $record->EVFE, 0,                'Event ID Field Exists';
    is $record->OBFE, 1,                'Object ID Field Exists';

    is $record->OID, $CAR_ID,           'Object Identifier';

    is $record->SST, EGTS_TELEDATA_SERVICE, 'Source Service Type';
    is $record->RST, EGTS_TELEDATA_SERVICE, 'Recipient Service Type';


    is scalar(@{ $record->subrecords }), 1, 'one subrecord';

    my $subrecord = $record->subrecords->[0];
    isa_ok $subrecord, 'Net::EGTS::SubRecord';
    note $subrecord->as_debug;

    is $subrecord->SRT, EGTS_SR_POS_DATA,   'Subrecord Туре';
    is $subrecord->SRL, 21,                 'Subrecord Length';

    is
        strftime('%F %T +0000', gmtime new2time($subrecord->NTM)),
        '2018-07-06 10:47:43 +0000',
        'Navigation Time'
    ;

    is
        sprintf('%.6f', mod2lat( $subrecord->LAT, $subrecord->LAHS )),
        55.767856,
        'Latitude'
    ;
    is
        sprintf('%.6f', mod2lon( $subrecord->LONG, $subrecord->LOHS )),
        37.672935,
        'Longitude'
    ;

    is $subrecord->ALTE, 0,                 'altitude exists';
    is $subrecord->LOHS, 0,                 'east/west';
    is $subrecord->LAHS, 0,                 'south/nord';
    is $subrecord->MV, 0,                   'move';
    is $subrecord->BB, 0,                   'from storage';
    is $subrecord->CS, 0,                   'coordinate system';
    is $subrecord->FIX, 1,                  '2d/3d';
    is $subrecord->VLD, 1,                  'valid';

    is $subrecord->SPD_LO, 0,               'Speed (lower bits)';
    is $subrecord->DIRH, 0,                 'Direction the Highest bit';
    is $subrecord->ALTS, 0,                 'Altitude Sign';
    is $subrecord->SPD_HI, 0,               'Speed (highest bits)';

    is $subrecord->DIR, 0,                  'Direction';
    SKIP: {
        skip 'TODO: fix BYNARY3 type', 1;
        is $subrecord->ODM, 0,                 'Odometer';
    }
    is $subrecord->DIN, 0,                  'Digital Inputs';
    is $subrecord->SRC, EGTS_SRCD_TIMER,    'Source';

    is $subrecord->ALT, undef,              'Altitude';
    is $subrecord->SRCD, undef,             'Source Data';
};


subtest 'recv' => sub {
    plan tests => 39;

    my $test = q(
        00000001 00000000 00000011 00001011
        00000000 00010000 00000000 00000010
        00000000 00000000 00111111 00000001
        00000000 00000000 00000110 00000000
        00000010 00000000 00011000 00000010
        00000010 00000000 00000011 00000000
        00000001 00000000 00000000 01010000
        10100001
    );
    s{[^01]}{}g, $_ = pack('B*' => $_) for $test;

    my $bin = "$test";
    my $packet = Net::EGTS::Packet->stream( \$bin );
    isa_ok $packet, 'Net::EGTS::Packet::Response';

    note $packet->as_debug;

    is $packet->PRV, 1,                 'Protocol Version';
    is $packet->SKID, 0,                'Security Key ID';

    is $packet->PRF, 0,                 'Prefix';
    is $packet->RTE, 0,                 'Route';
    is $packet->ENA, 0,                 'Encryption Algorithm';
    is $packet->CMP, 0,                 'Compressed';
    is $packet->PRIORITY,  3,           'Priority';

    is $packet->HL,  11,                'Header Length';
    is $packet->HE,  0,                 'Header Encoding';
    is $packet->FDL, 16,                'Frame Data Length';
    is $packet->PID, 2,                 'Packet Identifier';
    is $packet->PT,  EGTS_PT_RESPONSE,  'Packet Type';
    is $packet->HCS, 63,                 'Header Check Sum';

    is length($packet->SFRD), 16,       'Service Frame Data';
    is $packet->SFRCS, 41296,           'Service Frame Data Check Sum';

    is scalar(@{ $packet->records }), 1, 'one record';

    my $record = $packet->records->[0];
    isa_ok $record, 'Net::EGTS::Record';
    note $record->as_debug;

    is $record->RL, 6,                  'Record Length';
    is $record->RN, 2,                  'Record Number';

    is $record->SSOD, 0,                'Source Service On Device';
    is $record->RSOD, 0,                'Recipient Service On Device';
    is $record->GRP, 0,                 'Group';
    is $record->RPP, 3,                 'Record Processing Priority';
    is $record->TMFE, 0,                'Time Field Exists';
    is $record->EVFE, 0,                'Event ID Field Exists';
    is $record->OBFE, 0,                'Object ID Field Exists';

    is $record->OID, undef,             'Object Identifier';
    is $record->EVID, undef,            'Event Identifier';
    is $record->TM, undef,              'Time';

    is $record->SST, EGTS_TELEDATA_SERVICE, 'Source Service Type';
    is $record->RST, EGTS_TELEDATA_SERVICE, 'Recipient Service Type';

    is scalar(@{ $record->subrecords }), 1, 'one subrecord';

    my $subrecord = $record->subrecords->[0];
    isa_ok $subrecord, 'Net::EGTS::SubRecord::Auth::RecordResponse';
    note $subrecord->as_debug;

    is $subrecord->SRT, EGTS_SR_RECORD_RESPONSE,   'Subrecord Туре';
    is $subrecord->SRL, 3,              'Subrecord Length';

    is $subrecord->CRN,  1,             'Confirmed Record Number';
    is $subrecord->RST,  EGTS_PC_OK,    'Record Status';

    is
        dumper_bitstring($packet->encode),
        dumper_bitstring($test),
        'decode/encode'
    ;

};
