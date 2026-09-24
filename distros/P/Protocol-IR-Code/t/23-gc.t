#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use JSON::PP;
use Protocol::IR::Converter;

my $converter = Protocol::IR::Converter->new();

my $gc_json = <<'JSON';
{
  "commands": [
    {
      "keycode": "G:Memorex 32 Bit:()(0xC10000FF)():3",
      "name": "PowerToggle",
      "pronto": "0000 006D 0022 0000 0156 00AB 0017 003D 0017 003D 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 003D 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 003D 0017 003D 0017 003D 0017 003D 0017 003D 0017 003D 0017 003D 0017 003D 0017 0663",
      "protocol": "Memorex 32 Bit"
    },
    {
      "keycode": "G:Memorex 32 Bit:()(0xC10040BF)():3",
      "name": "VolumeUp",
      "pronto": "0000 006D 0022 0000 0156 00AB 0017 003D 0017 003D 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 003D 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 003D 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 0013 0017 003D 0017 0013 0017 003D 0017 003D 0017 003D 0017 003D 0017 003D 0017 003D 0017 0663",
      "protocol": "Memorex 32 Bit"
    }
  ]
}
JSON

my $codes = $converter->import_format('GCIR', $gc_json);
is(scalar(@$codes), 2, 'imported two commands');

my ($power, $vol) = @$codes;
is($power->alias,    'PowerToggle', 'alias comes from name');
is($power->protocol, 'NEC',         'NEC decoded from the Pronto payload');
is($power->bits,     32,            '32-bit');
is($power->address,  131,           'address 131');
is($power->subaddress, 0,           'subaddress 0');
is($power->command,  0,             'command 0');
is($power->data,      0x830000FF,   'display-form data');
is($vol->alias,       'VolumeUp',   'second command alias');
is($vol->command,     2,            'second command');
is($vol->data,        0x830002FD,   'second display-form data');

my $global_cache = $converter->import_format('GlobalCache', $gc_json);
is($global_cache->[0]->alias, 'PowerToggle', 'GlobalCache is an alias for GCIR');

my $via_wig = $converter->import_format('wig', $gc_json);
is(scalar(@$via_wig), 2, 'wig entry point imports a GC export interchangeably');
is($via_wig->[0]->alias, 'PowerToggle', 'wig import uses the GC command name');
is($via_wig->[0]->data,  0x830000FF,   'wig import decodes the same payload');
is($via_wig->[1]->command, 2,          'wig import second command');

# The keycode suffix ":N" is the GC repeat count; some exports also carry an
# explicit "repeats" field, which wins when present. Both must land on the
# code's send_count and ride a wig round trip.
is($power->send_count, 3,            'repeat count parsed from the keycode suffix');
is($vol->send_count,   3,            'second command keycode suffix parsed too');
is($via_wig->[0]->send_count, 3,     'wig gateway keeps the repeat count');

my $field_repeat_json = '{"commands": [{"keycode": "G:Memorex 32 Bit:()(0xC100E01F)():4", "name": "FieldWins", "repeats": 2, "pronto": "0000 006D 0002 0000 0071 0072 0013 0013"}]}';
my $field_repeat = $converter->import_format('GCIR', $field_repeat_json);
is($field_repeat->[0]->send_count, 2, 'an explicit repeats field wins over the keycode suffix');

my $no_repeat_json = '{"commands": [{"keycode": "G:Memorex 32 Bit:()(0xC100E01F)()", "name": "NoRepeat", "pronto": "0000 006D 0002 0000 0071 0072 0013 0013"}]}';
my $no_repeat = $converter->import_format('GCIR', $no_repeat_json);
is($no_repeat->[0]->send_count, 0, 'no repeat recorded stays the single-press default');

my $power_wig = $converter->export_code($power, 'wig');
my $power_doc = JSON::PP->new->decode($power_wig);
is($power_doc->{signals}[0]{send_count}, 3, 'wig carries the repeat count as send_count');
my $wig_back = $converter->import_format('wig', $power_wig);
is($wig_back->[0]->send_count, 3, 'wig -> code preserves send_count');

my $no_repeat_wig = JSON::PP->new->decode($converter->export_code($no_repeat->[0], 'wig'));
ok(!exists $no_repeat_wig->{signals}[0]{send_count}, 'default single press is not written to the wig');

# Pronto export is pulse-quantized, so re-importing the export must
# preserve the decoded fields (as the wig tests establish for the payload).
my $round = $converter->import_format('Pronto', $converter->export_code($power, 'Pronto'));
is($round->protocol,   'NEC',         'round-trip keeps protocol');
is($round->address,    131,           'round-trip keeps address');
is($round->command,    0,             'round-trip keeps command');
is($round->data,       0x830000FF,    'round-trip keeps data');

# Import from a file path.
my ($fh, $path) = tempfile();
print {$fh} $gc_json;
close $fh;
my $from_file = $converter->import_format('GCIR', $path);
is(scalar(@$from_file), 2, 'import from file path');

my $wig_guard = $converter->import_format('wig', $path);
is($wig_guard->[0]->alias, 'PowerToggle', 'wig gateway also reads from a path');

# Error handling.
eval { $converter->import_format('GCIR', undef); };
like($@, qr/^No GC input/, 'rejects missing input');

eval { $converter->import_format('GCIR', '{ not json'); };
like($@, qr/^Invalid GC JSON/, 'rejects invalid JSON');

eval { $converter->import_format('GCIR', '[1,2,3]'); };
like($@, qr/^GC top level must be a JSON object/, 'rejects non-object');

eval { $converter->import_format('GCIR', '{}'); };
like($@, qr/^GC requires a commands list/, 'rejects missing commands');

eval { $converter->import_format('GCIR', '{"commands": []}'); };
like($@, qr/^GC requires a commands list/, 'rejects empty commands');

my $no_pronto = eval { $converter->import_format('GCIR', '{"commands": [{"name": "X"}]}'); };
ok(!$@ && $no_pronto && @$no_pronto == 0, 'skips a command with no pronto payload');

my $some_payload = $converter->import_format('GCIR',
    '{"commands": [{"name": "X"}, {"name": "Y", "pronto": "0000 006D 0002 0000 0071 0072 0013 0013"}]}');
is(scalar(@$some_payload), 1, 'imports payload-bearing commands, skips the rest');

eval { $converter->import_format('GCIR', '{"commands": [{"name": "", "pronto": "0000 006D 0022 0000"}]}'); };
like($@, qr/missing its name/, 'rejects empty name');

eval { $converter->import_format('GCIR', '{"commands": [{"name": "X", "pronto": "nonsense"}]}'); };
like($@, qr/cannot be decoded/, 'rejects undecodable pronto');

# A wig-shaped document is not treated as GC.
eval { $converter->import_format('GCIR', '{"format": "hair-wig/3", "name": "R", "signals": []}'); };
like($@, qr/^GC requires a commands list/, 'a wig document is not GC');

# --- Undecodable (unknown-protocol) payloads pass through losslessly -------

# Three commands extracted from a real Global Cache export for an "Eufy 40
# Bit" remote (no registered protocol names it). The workspace copies of the
# files are local-only, never shipped; the payloads are embedded here so the
# test runs from any checkout.
my $eufy_gc_json = <<'JSON';
{
  "commands": [
    {
      "keycode": "G:Eufy 40 Bit:()(0x68A0000008)():3",
      "name": "Auto",
      "pronto": "0000 006D 002A 0000 0071 0072 0013 0013 0013 0039 0013 0039 0013 0013 0013 0039 0013 0013 0013 0013 0013 0013 0013 0039 0013 0013 0013 0039 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0039 0013 0013 0013 0013 0013 0013 0013 0304",
      "protocol": "Eufy 40 Bit"
    },
    {
      "keycode": "G:Eufy 40 Bit:()(0x68450632E5)():3",
      "name": "CurrentTime",
      "pronto": "0000 006D 002A 0000 0071 0072 0013 0013 0013 0039 0013 0039 0013 0013 0013 0039 0013 0013 0013 0013 0013 0013 0013 0013 0013 0039 0013 0013 0013 0013 0013 0013 0013 0039 0013 0013 0013 0039 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0039 0013 0039 0013 0013 0013 0013 0013 0013 0013 0039 0013 0039 0013 0013 0013 0013 0013 0039 0013 0013 0013 0039 0013 0039 0013 0039 0013 0013 0013 0013 0013 0039 0013 0013 0013 0039 0013 0304",
      "protocol": "Eufy 40 Bit"
    }
  ]
}
JSON

subtest 'unknown-protocol GC payload converts via wig' => sub {
    use JSON::PP;

    my $codes = $converter->import_format('GCIR', $eufy_gc_json);
    is(scalar(@$codes), 2, 'imports every command (Eufy 40 Bit is not registered)');
    my $auto = (grep { $_->alias eq 'Auto' } @$codes)[0];
    ok($auto, 'Auto decoded') or return;
    is($auto->alias,    'Auto',     'alias from the command name');
    is($auto->protocol, 'UNKNOWN',  'unknown protocol imports as UNKNOWN');
    is($auto->bypass_protocol, 1,   'raw code sets bypass_protocol');
    is($codes->[1]->alias, 'CurrentTime', 'second command imported as UNKNOWN too');

    my $raw = JSON::PP->new->decode($eufy_gc_json);
    my $orig = $raw->{commands}[0]{pronto};
    is($auto->pronto, $orig, 'original Pronto hex stashed verbatim');
    is($converter->export_code($auto, 'Pronto'), $orig,
        'Pronto export re-emits the stashed hex');

    my $wig = $converter->export_code($auto, 'wig');
    my $doc = JSON::PP->new->decode($wig);
    is($doc->{signals}[0]{bypass_protocol}, JSON::PP::true,
        'wig keeps bypass_protocol');
    is($doc->{signals}[0]{pronto},   $orig,     'wig keeps pronto hex verbatim');

    my $wig_codes = $converter->import_format('wig', $wig);
    is(scalar(@$wig_codes), 1, 'wig round-trips to one code');
    is($wig_codes->[0]->pronto, $orig, 'wig -> code keeps pronto hex');

    # Mode2/Tasmota uses the retained timings instead.
    like($converter->export_code($auto, 'Mode2'), qr/^pulse 29\d{2}/m,
        'mode2 export uses decoded timings');
};

done_testing;