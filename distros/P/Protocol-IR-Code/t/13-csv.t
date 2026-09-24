#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Protocol::IR::Converter;

my $converter = Protocol::IR::Converter->new();

my $csv = <<'CSV';
functionname,protocol,device,subdevice,function
KEY_POWER,NEC1,4,0,8
KEY_MUTE,NEC1,4,0,9
KEY_VOLUP,JVC,3,-1,12
CSV

my $codes = $converter->import_format('CSV', $csv);
is(scalar(@$codes), 3, 'parsed three rows');
is($codes->[0]->alias,    'KEY_POWER', 'alias extracted');
is($codes->[0]->protocol, 'NEC',       'NEC1 normalized to NEC');
is($codes->[0]->address,  4,           'device column maps to address');
is($codes->[1]->command,  9,           'function column maps to command');
is($codes->[2]->protocol, 'JVC',       'JVC row parsed');
is($codes->[2]->subaddress, -1,        'JVC leaves subaddress unset');

my $raw_csv = <<'CSV';
name,protocol,data
KEY_ON,NEC,0x10EF00FF
CSV
my $raw_codes = $converter->import_format('CSV', $raw_csv);
is(scalar(@$raw_codes), 1, 'raw data row parsed');
is($raw_codes->[0]->data, 0x10EF00FF, 'raw hex data imported');

# Real IRDB files mix in protocols we do not register; those rows must be
# skipped, not fatal, as the POD documents. NEC-variant rows now decode.
my $mixed_csv = <<'CSV';
functionname,protocol,device,subdevice,function
KEY_POWER,NEC1,4,0,8
KEY_SONY,Sony12,1,0,2
KEY_ON,NECX2,25,-1,8
KEY_MUTE2,NEC2,26,232,5
KEY_PLAY,JVC,3,-1,12
CSV
my $mixed = $converter->import_format('CSV', $mixed_csv);
is(scalar(@$mixed), 4, 'unregistered protocol rows are skipped');
is($mixed->[0]->protocol, 'NEC',   'NEC row kept');
is($mixed->[1]->protocol, 'NECX2', 'NECx2 row kept with subdevice defaulting to device');
is($mixed->[1]->data,     0x191908F7, 'NECx2 25,-1,8 packs with S=D');
is($mixed->[2]->protocol, 'NEC2',  'NEC2 row kept');
is($mixed->[2]->data,     0x1AE805FA, 'NEC2 row keeps explicit subdevice');
is($mixed->[3]->protocol, 'JVC',   'JVC row kept');

eval { $converter->import_format('CSV', undef); };
like($@, qr/no csv input/i, 'rejects missing input');

eval { $converter->import_format('CSV', "\n"); };
like($@, qr/empty/i, 'rejects input with no content');

done_testing;
