#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Protocol::IR::Converter;

my $converter = Protocol::IR::Converter->new();

my @specs = (
    { proto => 'NEC', args => '0x10EF00FF' },
    { proto => 'NEC', args => { address => 4, subaddress => 0, command => 8 } },
    { proto => 'JVC', args => '0x030C' },
    { proto => 'JVC', args => { address => 3, command => 12 } },
    { proto => 'SAMSUNG', args => '0xE0E040BF' },
    { proto => 'SAMSUNG', args => { address => 0xE0, command => 0x40 } },
    { proto => 'SAMSUNG', args => { address => 4, command => 0xFF } },
);

for my $spec (@specs) {
    my $orig    = $converter->import_code($spec->{proto}, $spec->{args});
    my $pronto  = $converter->export_code($orig, 'Pronto');
    my $decoded = $converter->import_format('Pronto', $pronto);

    is($decoded->protocol, $orig->protocol, "$spec->{proto} protocol survives roundtrip");
    is($decoded->address,  $orig->address,  "$spec->{proto} address survives roundtrip");
    is($decoded->command,  $orig->command,  "$spec->{proto} command survives roundtrip");
    is($decoded->data,     $orig->data,     "$spec->{proto} data survives roundtrip");
}

done_testing;
