#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 6;

BEGIN {
    use_ok 'Net::EGTS::Packet';
    use_ok 'Net::EGTS::Record';
    use_ok 'Net::EGTS::Util';
    use_ok 'Net::EGTS::Codes';
}

subtest 'send' => sub {
    plan tests => 40;

    my $SERVICE_ID = 2002;

    my $test = q(
        00000001 00000000 00000011 00001011
        00000000 00001111 00000000 00000000
        00000000 00000001 10011011 00001000
        00000000 00000000 00000000 00000000
        00000001 00000001 00000101 00000101
        00000000 00000000 11010010 00000111
        00000000 00000000 00000010 00011100
    );
    s{[^01]}{}g, $_ = pack('B*' => $_) for $test;

    my $bin = "$test";
    my $packet = Net::EGTS::Packet->stream( \$bin );
    isa_ok $packet, 'Net::EGTS::Packet::Appdata';

    note $packet->as_debug;

    is $packet->PRV, 1, 'Protocol Version';
    is $packet->SKID, 0, 'Security Key ID';

    is $packet->PRF, 0, 'Prefix';
    is $packet->RTE, 0, 'Route';
    is $packet->ENA, 0, 'Encryption Algorithm';
    is $packet->CMP, 0, 'Compressed';
    is $packet->PRIORITY,  3, 'Priority';

    is $packet->HL,  11, 'Header Length';
    is $packet->HE,  0, 'Header Encoding';
    is $packet->FDL, 15, 'Frame Data Length';
    is $packet->PID, 0, 'Packet Identifier';
    is $packet->PT,  EGTS_PT_APPDATA, 'Packet Type';
    is $packet->HCS, 155, 'Header Check Sum';

    is length($packet->SFRD), 15, 'Service Frame Data';
    is $packet->SFRCS, 7170, 'Service Frame Data Check Sum';

    is scalar(@{ $packet->records }), 1, 'one record';

    my $record = $packet->records->[0];
    isa_ok $record, 'Net::EGTS::Record';
    note $record->as_debug;

    is $record->RL, 8,                  'Record Length';
    is $record->RN, 0,                  'Record Number';

    is $record->SSOD, 0,                'Source Service On Device';
    is $record->RSOD, 0,                'Recipient Service On Device';
    is $record->GRP, 0,                 'Group';
    is $record->RPP, 0,                 'Record Processing Priority';
    is $record->TMFE, 0,                'Time Field Exists';
    is $record->EVFE, 0,                'Event ID Field Exists';
    is $record->OBFE, 0,                'Object ID Field Exists';

    is $record->OID, undef,             'Object Identifier';
    is $record->EVID, undef,            'Event Identifier';
    is $record->TM, undef,              'Time';

    is $record->SST, EGTS_AUTH_SERVICE, 'Source Service Type';
    is $record->RST, EGTS_AUTH_SERVICE, 'Recipient Service Type';

    is scalar(@{ $record->subrecords }), 1, 'one subrecord';

    my $subrecord = $record->subrecords->[0];
    isa_ok $subrecord, 'Net::EGTS::SubRecord::Auth::DispatcherIdentity';
    note $subrecord->as_debug;

    is $subrecord->SRT, EGTS_SR_DISPATCHER_IDENTITY,   'Subrecord Туре';
    is $subrecord->SRL, 5,              'Subrecord Length';

    is $subrecord->DT,  0,              'Dispatcher Type';
    is $subrecord->DID,  $SERVICE_ID,   'Dispatcher ID';
    is $subrecord->DSCR, '',            'Description';

    is
        dumper_bitstring($packet->encode),
        dumper_bitstring($test),
        'decode/encode'
    ;
};

subtest 'send - partial decoding' => sub {
    plan tests => 11;

    my $test = q(
        00000001 00000000 00000011 00001011
        00000000 00001111 00000000 00000000
        00000000 00000001 10011011 00001000
        00000000 00000000 00000000 10000000
        01000000 00000001 00000101 00000101
        00000000 00000000 11010010 00000111
        00000000 00000000 11110111 10001000
    );
    s{[^01]}{}g, $_ = pack('B*' => $_) for $test;

    my $bin = "$test";
    my $in  = '';
    is length($bin), 28, 'bufer length 28';

    $in .= substr $bin, 0 => 3, '';
    my ($res1, $need1) = Net::EGTS::Packet->stream( \$in );
    is $res1, undef, 'Undefined';
    is $need1, 10, 'Need more for header complete';
    is length($in), 3, 'bufer not truncated';

    $in .= substr $bin, 0 => 10, '';
    my ($res2, $need2) = Net::EGTS::Packet->stream( \$in );
    is $res2, undef, 'Undefined';
    is $need2, 28, 'Need more for data complete';
    is length($in), 13, 'bufer truncated by header';

    $in .= substr $bin, 0 => 15, '';
    my ($res3, $need3) = Net::EGTS::Packet->stream( \$in );
    isa_ok $res3, 'Net::EGTS::Packet', 'Decode complete';
    is $need3, undef, 'No need more for data complete';
    is length($in), 0, 'bufer truncated by data';

    note $res3->as_debug;

    is
        dumper_bitstring($res3->encode),
        dumper_bitstring($test),
        'decode/encode'
    ;
};
