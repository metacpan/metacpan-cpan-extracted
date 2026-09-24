#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;

use lib 'lib';
use Protocol::IR::Converter;

my $converter = Protocol::IR::Converter->new();

# Sample IRDB CSV Content
my $csv_data = <<'CSV';
functionname,protocol,device,subdevice,function
KEY_POWER,NEC1,4,0,8
KEY_MUTE,NEC1,4,0,9
KEY_VOLUP,JVC,3,-1,12
CSV

print "=== Testing IRDB CSV Import ===\n";
my $codes = $converter->import_format('CSV', $csv_data);

for my $code (@$codes) {
    print "Button: " . $code->alias . "\n";
    print "  IRSend: " . Dumper($code->to_irsend());
    print "  Pronto: " . $converter->export_code($code, 'Pronto') . "\n\n";
}
