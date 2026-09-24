#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib';
use Protocol::IR::Converter;

my $converter = Protocol::IR::Converter->new();

print "=== Generating a wig from Protocol::IR::Code objects ===\n";
my @codes = (
    $converter->import_code('NEC', '0x10EF00FF'),
    $converter->import_code('JVC', { address => 0x03, command => 0x0C }),
);
$codes[0]->alias('POWER');
$codes[0]->ditto_count(1);
$codes[1]->alias('VOLUME_UP');

my $wig = $converter->export_codes('wig', \@codes,
    name    => 'Demo Remote',
    brand   => 'Demo',
    kind    => 'tv',
    origin  => 'converted by Protocol::IR::Converter',
);
print $wig;

print "\n=== Round-tripping wig back into Protocol::IR::Code objects ===\n";
my $imported = $converter->import_format('wig', $wig);
for my $c (@$imported) {
    printf "%-12s protocol=%-4s ditto=%d bypass=%d\n",
        $c->alias, $c->protocol, $c->ditto_count, $c->bypass_protocol;
}
