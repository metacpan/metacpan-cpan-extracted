#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;

use lib 'lib';
use Protocol::IR::Converter;

my $converter = Protocol::IR::Converter->new();

# -------------------------------------------------------------------
# Example 1: Import 32-bit HEX via NEC Importer -> Intermediate Code
# -------------------------------------------------------------------
my $nec_hex = "0x10EF00FF";
my $ir_code_1 = $converter->import_code('NEC', $nec_hex);

print "--- NEC Raw 32-bit Import ---\n";
print "IRSEND Hash Representation:\n";
print Dumper($ir_code_1->to_irsend());

# Export intermediate representation to Pronto Hex
my $pronto_1 = $converter->export_code($ir_code_1, 'Pronto');
print "Pronto Hex Export:\n$pronto_1\n\n";

# -------------------------------------------------------------------
# Example 2: Import Discrete Parameters via JVC Importer
# -------------------------------------------------------------------
my $jvc_params = { address => 3, command => 12 };
my $ir_code_2 = $converter->import_code('JVC', $jvc_params);

print "--- JVC Parameter Import ---\n";
print "IRSEND Hash Representation:\n";
print Dumper($ir_code_2->to_irsend());

my $pronto_2 = $converter->export_code($ir_code_2, 'Pronto');
print "Pronto Hex Export:\n$pronto_2\n";
