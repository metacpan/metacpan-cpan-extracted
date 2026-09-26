#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);
use Cwd ();
use JSON::PP;
use Protocol::IR::Converter;

my $converter = Protocol::IR::Converter->new();

my $codeset_json = <<'JSON';
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

my $codes = $converter->import_format('JSON', $codeset_json);
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

my $via_wig = $converter->import_format('wig', $codeset_json);
is(scalar(@$via_wig), 2, 'wig entry point imports a dump document interchangeably');
is($via_wig->[0]->alias, 'PowerToggle', 'wig import uses the command name');
is($via_wig->[0]->data,  0x830000FF,   'wig import decodes the same payload');
is($via_wig->[1]->command, 2,          'wig import second command');

# The number after a keycode's last colon is the command's repeat hint: how
# many times one press transmits.  It rides send_count and survives a wig
# round trip.  Most commands hint the same value, but it does vary.
is($power->send_count, 3, 'repeat hint parsed from the keycode');
is($vol->send_count,   3, 'second command hint parsed too');
is($via_wig->[0]->send_count, 3, 'the wig entry point keeps the hint');

my $hint_4 = $converter->import_format('JSON',
    '{"commands": [{"keycode": "G:Toshiba 32 Bit:(0x407F58A7)(Repeat)():4",'
    . ' "name": "Power",'
    . ' "pronto": "0000 006D 0002 0000 0071 0072 0013 0013"}]}');
is($hint_4->[0]->send_count, 4, 'a hint other than 3 is read too');

# A keycode with no usable hint keeps the single-press default, which the wig
# exporter then leaves out.
my $no_hint;
for my $keycode ('G:MemorexO1 32 Bit:(0x7689906F)(Repeat)()',
                 'G:Memorex 32 Bit:()(0xC100E01F)()',
                 'G:Memorex 32 Bit:()(0xC100E01F)():0') {
    my $json = sprintf
        '{"commands": [{"keycode": "%s", "name": "X",'
        . ' "pronto": "0000 006D 0002 0000 0071 0072 0013 0013"}]}', $keycode;
    $no_hint = $converter->import_format('JSON', $json);
    is($no_hint->[0]->send_count, 0, "no usable hint in $keycode");
}

my $power_wig = $converter->export_code($power, 'wig');
is(JSON::PP->new->decode($power_wig)->{signals}[0]{send_count}, 3,
    'wig carries the hint as send_count');
is($converter->import_format('wig', $power_wig)->[0]->send_count, 3,
    'wig -> code preserves the hint');
is(JSON::PP->new->decode($converter->export_code($hint_4->[0], 'wig'))
       ->{signals}[0]{send_count}, 4, 'a hint of 4 rides a wig export');
ok(!exists JSON::PP->new->decode($converter->export_code($no_hint->[0], 'wig'))
       ->{signals}[0]{send_count}, 'a code with no hint omits send_count');

# A device document carries no commands of its own, only a "codeset" path
# to the re-usable command set shared by every device with those commands.
# The path is relative to the dump root, so it is resolved by walking up
# from the device file.
subtest 'device document follows its code set pointer' => sub {
    my $root = tempdir(CLEANUP => 1);
    make_path(File::Spec->catdir($root, 'devices', 'JVC'));
    make_path(File::Spec->catdir($root, 'codesets', 'dd'));

    _write(File::Spec->catfile($root, 'codesets', 'dd', 'ddc59c768a8b0c95.json'),
        $codeset_json);
    _write(File::Spec->catfile($root, 'devices', 'JVC', 'EM40NF5.json'),
        '{"codeset": "codesets/dd/ddc59c768a8b0c95.json", '
        . '"manufacturer": "JVC", "model": "EM40NF5"}');

    my $device = File::Spec->catfile($root, 'devices', 'JVC', 'EM40NF5.json');
    my $imported = $converter->import_format('JSON', $device);
    is(scalar(@$imported), 2, 'absolute device path resolves its code set');
    is($imported->[0]->alias, 'PowerToggle', 'alias from the code set');

    # The same document, addressed relative to the dump root.
    my $cwd = Cwd::getcwd();
    chdir $root or die "chdir $root: $!";
    my $relative = $converter->import_format('JSON', 'devices/JVC/EM40NF5.json');
    chdir $cwd or die "chdir $cwd: $!";
    is(scalar(@$relative), 2, 'relative device path resolves its code set');

    is(scalar(@{$converter->import_format('wig', $device)}), 2,
        'the wig entry point follows the pointer too');

    _write(File::Spec->catfile($root, 'devices', 'JVC', 'Orphan.json'),
        '{"codeset": "codesets/ff/missing.json"}');
    eval { $converter->import_format('JSON',
        File::Spec->catfile($root, 'devices', 'JVC', 'Orphan.json')) };
    like($@, qr/^Cannot find the code set 'codesets\/ff\/missing.json'/,
        'an unresolvable pointer is reported');
};

# Pronto export is pulse-quantized, so re-importing the export must
# preserve the decoded fields (as the wig tests establish for the payload).
my $round = $converter->import_format('Pronto', $converter->export_code($power, 'Pronto'));
is($round->protocol,   'NEC',         'round-trip keeps protocol');
is($round->address,    131,           'round-trip keeps address');
is($round->command,    0,             'round-trip keeps command');
is($round->data,       0x830000FF,    'round-trip keeps data');

# Decoded commands export as IRDB CSV rows; a code no registered protocol
# decoded (Eufy 40 Bit) has no keyable address and is skipped.
my $csv = $converter->export_codes('CSV', [$power, $vol, (grep { $_->alias eq 'Auto' } @$codes)[0]]);
is($csv, "functionname,protocol,device,subdevice,function\n"
       . "PowerToggle,NEC,131,0,0\n"
       . "VolumeUp,NEC,131,0,2\n", 'imported codes export as IRDB rows');
my $csv_back = $converter->import_format('CSV', $csv);
is(scalar(@$csv_back), 2, 'CSV export re-imports');
is($csv_back->[1]->command, 2, 'round-trip keeps the command');

# Import from a file path.
my $path = File::Spec->catfile(tempdir(CLEANUP => 1), 'codeset.json');
_write($path, $codeset_json);
my $from_file = $converter->import_format('JSON', $path);
is(scalar(@$from_file), 2, 'import from file path');

my $wig_guard = $converter->import_format('wig', $path);
is($wig_guard->[0]->alias, 'PowerToggle', 'wig gateway also reads from a path');

# Error handling.
eval { $converter->import_format('JSON', undef); };
like($@, qr/^No JSON input/, 'rejects missing input');

eval { $converter->import_format('JSON', '{ not json'); };
like($@, qr/^Invalid JSON/, 'rejects invalid JSON');

eval { $converter->import_format('JSON', '[1,2,3]'); };
like($@, qr/^JSON top level must be a JSON object/, 'rejects non-object');

eval { $converter->import_format('JSON', '{}'); };
like($@, qr/^JSON requires a commands list/, 'rejects missing commands');

eval { $converter->import_format('JSON', '{"commands": []}'); };
like($@, qr/^JSON requires a commands list/, 'rejects empty commands');

my $no_pronto = eval { $converter->import_format('JSON', '{"commands": [{"name": "X"}]}') };
ok(!$@ && $no_pronto && @$no_pronto == 0, 'skips a command with no pronto payload');

my $some_payload = $converter->import_format('JSON',
    '{"commands": [{"name": "X"}, {"name": "Y", "pronto": "0000 006D 0002 0000 0071 0072 0013 0013"}]}');
is(scalar(@$some_payload), 1, 'imports payload-bearing commands, skips the rest');

eval { $converter->import_format('JSON', '{"commands": [{"name": "", "pronto": "0000 006D 0022 0000"}]}') };
like($@, qr/missing its name/, 'rejects empty name');

eval { $converter->import_format('JSON', '{"commands": [{"name": "X", "pronto": "nonsense"}]}') };
like($@, qr/cannot be decoded/, 'rejects undecodable pronto');

# A wig-shaped document is not mistaken for a dump document.
eval { $converter->import_format('JSON', '{"format": "hair-wig/3", "name": "R", "signals": []}') };
like($@, qr/^JSON requires a commands list/, 'a wig document is rejected');

# --- Undecodable (unknown-protocol) payloads pass through losslessly -------

# Two commands from a real dump's code set for a remote whose protocol no
# registered handler names.  The dump is not redistributed, so the payloads
# are embedded here and the test runs from any checkout.
my $unknown_json = <<'JSON';
{
  "commands": [
    {
      "keycode": "G:Eufy 40 Bit:()(0x68A0000008)():3",
      "name": "Auto",
      "pronto": "0000 006D 002A 0000 0071 0072 0013 0013 0013 0039 0013 0039 0013 0013 0013 0039 0013 0013 0013 0013 0013 0013 0013 0039 0013 0013 0013 0039 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0304",
      "protocol": "Eufy 40 Bit"
    },
    {
      "keycode": "G:Eufy 40 Bit:()(0x68450632E5)():3",
      "name": "CurrentTime",
      "pronto": "0000 006D 002A 0000 0071 0072 0013 0013 0013 0039 0013 0039 0013 0013 0013 0039 0013 0013 0013 0013 0013 0013 0013 0039 0013 0013 0013 0039 0013 0013 0013 0013 0013 0013 0039 0013 0039 0013 0013 0013 0039 0013 0039 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0304",
      "protocol": "Eufy 40 Bit"
    }
  ]
}
JSON

subtest 'unknown-protocol payload converts via wig' => sub {
    my $imported = $converter->import_format('JSON', $unknown_json);
    is(scalar(@$imported), 2, 'imports every command (Eufy 40 Bit is not registered)');
    my $auto = (grep { $_->alias eq 'Auto' } @$imported)[0];
    ok($auto, 'Auto decoded') or return;
    is($auto->alias,    'Auto',     'alias from the command name');
    is($auto->protocol, 'UNKNOWN',  'unknown protocol imports as UNKNOWN');
    is($auto->bypass_protocol, 1,   'raw code sets bypass_protocol');
    is($imported->[1]->alias, 'CurrentTime', 'second command imported as UNKNOWN too');

    my $orig = JSON::PP->new->decode($unknown_json)->{commands}[0]{pronto};
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

sub _write {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot write '$path': $!";
    print {$fh} $content;
    close $fh;
}

done_testing;
