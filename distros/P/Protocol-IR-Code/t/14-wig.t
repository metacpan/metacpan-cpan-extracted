#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use JSON::PP;
use Protocol::IR::Converter;
use Protocol::IR::Code;

my $converter = Protocol::IR::Converter->new();

my @codes = (
    Protocol::IR::Code->new(
        protocol => 'NEC', bits => 32, data => 0x10EF00FF,
        address => 0x10, subaddress => -1, command => 0,
        alias => 'POWER',
    ),
    Protocol::IR::Code->new(
        protocol => 'JVC', bits => 16, data => 0x030C,
        address => 3, command => 12,
        alias => 'MUTE', ditto_count => 1, bypass_protocol => 1,
    ),
    Protocol::IR::Code->new(
        protocol => 'SAMSUNG', bits => 32, data => 0x070702FD,
        address => 0xE0, command => 0x40,
        alias => 'POWER',
    ),
);

my $wig_text = $converter->export_codes('wig', \@codes,
    name => 'Test Remote', brand => 'Acme', model => 'X-1');

my $data = JSON::PP->new->decode($wig_text);
is($data->{format}, 'hair-wig/3', 'exports hair-wig/3');
is($data->{name}, 'Test Remote', 'name carried through');
is($data->{brand}, 'Acme', 'brand carried through');
is($data->{model}, 'X-1', 'model carried through');
is($data->{origin}, 'converted by Protocol::IR::Converter', 'origin credits this library');
like($data->{wig_id}, qr/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
    'wig_id is a UUID v4');
is(scalar(@{$data->{signals}}), 3, 'three signals exported');

my %by_alias = map { $_->{alias} => $_ } @{$data->{signals}};
is($by_alias{POWER}{bypass_protocol}, JSON::PP::false, 'default bypass_protocol is false');
is($by_alias{POWER}{ditto_count}, 0, 'default ditto_count is zero');
is($by_alias{MUTE}{ditto_count}, 1, 'ditto_count exported');
is($by_alias{MUTE}{bypass_protocol}, JSON::PP::true, 'bypass_protocol exported');

# Roundtrip: import what we just exported.
my $back = $converter->import_format('wig', $wig_text);
is(scalar(@$back), 3, 'roundtrip decoded three signals');
is($back->[0]->alias, 'POWER', 'roundtrip alias');
is($back->[0]->protocol, 'NEC', 'roundtrip protocol');
is($back->[0]->data, 0x10EF00FF, 'roundtrip NEC data');
is($back->[1]->alias, 'MUTE', 'roundtrip JVC alias');
is($back->[1]->data, 0x030C, 'roundtrip JVC data');
is($back->[1]->ditto_count, 1, 'roundtrip ditto_count');
is($back->[1]->bypass_protocol, 1, 'roundtrip bypass_protocol');
is($back->[2]->alias, 'POWER', 'roundtrip SAMSUNG alias');
is($back->[2]->protocol, 'SAMSUNG', 'roundtrip SAMSUNG protocol');
is($back->[2]->data, 0x070702FD, 'roundtrip SAMSUNG data');

# Export of a single code (not an arrayref) also works.
my $single = $converter->export_codes('wig', $codes[0], name => 'Single');
is(scalar(@{JSON::PP->new->decode($single)->{signals}}), 1, 'single-code export');

# Import from a file path.
my ($fh, $path) = tempfile();
print {$fh} $wig_text;
close $fh;
my $from_file = $converter->import_format('wig', $path);
is(scalar(@$from_file), 3, 'import from file path');

# Import a wig with no signals.
my $empty_wig = $converter->export_codes('wig', [], name => 'Empty');
is(scalar(@{ $converter->import_format('wig', $empty_wig) }), 0, 'empty signal list');

# Error handling.
eval { $converter->import_format('wig', undef); };
like($@, qr/no wig input/i, 'rejects missing input');

eval { $converter->import_format('wig', '{ not json'); };
like($@, qr/invalid wig json/i, 'rejects invalid JSON');

eval { $converter->import_format('wig', '[1,2,3]'); };
like($@, qr/top level must be a json object/i, 'rejects non-object');

eval { $converter->import_format('wig', '{"format":"hair-wig/99","name":"X","signals":[]}'); };
like($@, qr/unsupported wig format/i, 'rejects unknown format major');

done_testing;
