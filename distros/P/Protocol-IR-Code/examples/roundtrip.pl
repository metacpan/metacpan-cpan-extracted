#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;

use lib 'lib';
use Protocol::IR::Converter;

my $converter = Protocol::IR::Converter->new();

print "=== Testing Pure Perl NEC Pronto Decoding ===\n";
my $nec_hex = "0x10EF00FF";
my $nec_code_orig = $converter->import_code('NEC', $nec_hex);
my $nec_pronto    = $converter->export_code($nec_code_orig, 'Pronto');

# Decode back from generated Pronto Hex string
my $nec_code_decoded = $converter->import_format('Pronto', $nec_pronto);

print "Original IRSend Data:  " . Dumper($nec_code_orig->to_irsend());
print "Decoded IRSend Data:   " . Dumper($nec_code_decoded->to_irsend());

print "\n=== Testing Pure Perl JVC Pronto Decoding ===\n";
my $jvc_params = { address => 0x03, command => 0x0C };
my $jvc_code_orig = $converter->import_code('JVC', $jvc_params);
my $jvc_pronto    = $converter->export_code($jvc_code_orig, 'Pronto');

# Decode back from generated Pronto Hex string
my $jvc_code_decoded = $converter->import_format('Pronto', $jvc_pronto);

print "Original IRSend Data:  " . Dumper($jvc_code_orig->to_irsend());
print "Decoded IRSend Data:   " . Dumper($jvc_code_decoded->to_irsend());
