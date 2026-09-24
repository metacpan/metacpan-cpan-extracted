#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Protocol::IR::Converter;

my $converter = Protocol::IR::Converter->new();

my $code   = $converter->import_code('NEC', { address => 4, subaddress => 0, command => 8 });
my $pronto = $converter->export_code($code, 'Pronto');

like($pronto, qr/^0000 [0-9A-F]{4} [0-9A-F]{4} 0000/, 'well-formed header');
my @tokens = split /\s+/, $pronto;
is(scalar(@tokens) % 2, 0, 'even number of hex tokens');
is($tokens[0], '0000', 'raw format marker');

eval { $converter->import_format('Pronto', 'short'); };
like($@, qr/too short/i, 'rejects too-short input');

eval { $converter->import_format('Pronto', '1000 006D 0000 0000'); };
like($@, qr/raw pronto/i, 'rejects non-raw format');

eval { $converter->import_format('Pronto', '0000 0000 0000 0000'); };
like($@, qr/unable to decode/i, 'rejects undecodable (empty) payload');

my $raw = $converter->import_format('Pronto', '0000 006D 0002 0000 0071 0072 0013 0013');
is($raw->protocol, 'UNKNOWN', 'unrecognized but well-formed payload imports as UNKNOWN');
is($raw->bypass_protocol, 1, 'raw code bypasses protocol decoding');
is($raw->pronto, '0000 006D 0002 0000 0071 0072 0013 0013',
    'original hex stashed verbatim');
is($converter->export_code($raw, 'Pronto'), '0000 006D 0002 0000 0071 0072 0013 0013',
    'raw code exports its stashed Pronto hex verbatim');

done_testing;
