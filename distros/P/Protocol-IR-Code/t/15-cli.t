#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP;
use Protocol::IR::Converter;

my $root = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..'));
my $data = File::Spec->catdir($root, 't', 'data');
my $converter = Protocol::IR::Converter->new();

# Generate a known-good Pronto Hex string for a protocol+data pair via the API.
sub pronto_for {
    my ($proto, $data) = @_;
    my $code = $converter->import_code($proto, $data);
    return $converter->export_code($code, 'Pronto');
}

# Run an installed-style bin/ script, capturing stdout and the exit code.
sub run_script {
    my ($script, @args) = @_;
    my $cmd = File::Spec->catfile($root, 'bin', $script);
    my @quoted = map { "'" . ($_ =~ s/'/'\\''/gr) . "'" } @args;
    # </dev/null: the tools fall back to reading input from STDIN when no
    # input file is given, which would otherwise block if the parent test's
    # stdin is an interactive terminal.
    my $out = `$^X $cmd @quoted 2>/dev/null </dev/null`;
    my $exit = $? >> 8;
    return ($out, $exit);
}

sub json_ok {
    my ($text, $name) = @_;
    my $data = eval { JSON::PP->new->utf8->decode($text) };
    ok(!$@, "$name parses as JSON") or diag($@);
    ok(ref $data eq 'HASH', "$name is a JSON object");
    return $data;
}

my $nec_csv = File::Spec->catfile($data, 'irdb-nec-receiver.csv');
my $jvc_csv = File::Spec->catfile($data, 'irdb-jvc-vcr.csv');

# --- ir-irdb2wig --------------------------------------------------------

subtest 'ir-irdb2wig converts a local IRDB CSV to a wig' => sub {
    my ($out, $exit) = run_script('ir-irdb2wig', $nec_csv,
        '--name', 'NEC Receiver', '--brand', 'Acme', '--model', 'M1',
        '--kind', 'vcr');
    is($exit, 0, 'exits 0');
    my $wig = json_ok($out, 'wig output');
    return unless $wig;
    is($wig->{format}, 'hair-wig/3', 'hair-wig/3 format');
    is($wig->{name}, 'NEC Receiver', 'name set');
    is($wig->{brand}, 'Acme', 'brand set');
    is($wig->{model}, 'M1', 'model set');
    is($wig->{kind}, 'vcr', 'kind set');
    is(scalar(@{ $wig->{signals} }), 7, 'all 7 NEC buttons converted');
    like($wig->{signals}[0]{pronto}, qr/^0000 /, 'signal carries Pronto hex');
    is($wig->{signals}[0]{alias}, 'VCR STOP []', 'button name kept as alias');
    is($wig->{origin}, 'converted:irdb', 'origin stamp set');
};

subtest 'ir-irdb2wig writes to --out and refuses to clobber' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $out = File::Spec->catfile($dir, 'out.wig.json');

    my ($o1, $e1) = run_script('ir-irdb2wig', $jvc_csv, '--out', $out, '--brand', 'Acme');
    is($e1, 0, 'writes exit 0');
    is($o1, '', 'nothing on stdout when writing to a file');

    my $wig = json_ok(_slurp($out), 'file output');
    is(scalar(@{ $wig->{signals} }), 5, 'JVC fixture yields 5 signals') if $wig;
    is($wig->{name}, 'Acme', 'name defaults from --brand') if $wig;

    my ($o2, $e2) = run_script('ir-irdb2wig', $jvc_csv, '--out', $out, '--brand', 'Acme');
    isnt($e2, 0, 'refuses to overwrite an existing file');

    my ($o3, $e3) = run_script('ir-irdb2wig', $jvc_csv, '--out', $out,
        '--overwrite', '--brand', 'Acme');
    is($e3, 0, 'overwrites with --overwrite');
};

subtest 'ir-irdb2wig usage errors' => sub {
    my ($out, $exit) = run_script('ir-irdb2wig');
    isnt($exit, 0, 'no arguments exits non-zero');

    my ($h, $he) = run_script('ir-irdb2wig', '--help');
    is($he, 0, '--help exits 0');
    like($h, qr/IRDB/, '--help mentions IRDB');
};

subtest 'ir-tasmota2wig converts a Tasmota dump to a wig' => sub {
    my $dir  = tempdir(CLEANUP => 1);
    my $dump = File::Spec->catfile($dir, 'dump.log');
    _slurp_write($dump, <<'DUMP');
17:12:31.100 IRrecv: Protocol = NEC, Bits = 32, Data = 0x10EF00FF
17:12:31.200 IRrecv: RawData = +8495-4070+660-1440C-1450+620-430+655-390H-400+645-405Ci+650jHeCdC-1445+625-425M-1480OjMjCiC
DUMP

    my ($out, $exit) = run_script('ir-tasmota2wig', $dump, '--name', 'Captured',
        '--kind', 'tv');
    is($exit, 0, 'exits 0');
    my $wig = json_ok($out, 'wig output');
    return unless $wig;
    is($wig->{format}, 'hair-wig/3', 'hair-wig/3 format');
    is($wig->{name}, 'Captured', 'name set');
    is($wig->{kind}, 'tv', 'kind set');
    is($wig->{origin}, 'converted:tasmota', 'origin stamp set');
    is(scalar(@{ $wig->{signals} }), 2, 'both signals converted');
    is($wig->{signals}[0]{alias}, '0x08F700FF', 'structured signal keeps the accumulated Data hex');
    is($wig->{signals}[1]{alias}, '0x0317', 'raw signal aliased to decoded Data hex');
    like($wig->{signals}[0]{pronto}, qr/^0000 /, 'signals carry Pronto hex');
};

subtest 'ir-tasmota2wig usage errors' => sub {
    my ($out, $exit) = run_script('ir-tasmota2wig', '--help');
    is($exit, 0, '--help exits 0');
    like($out, qr/HAIR wig/, '--help describes the tool');
};

# --- ir-convert ---------------------------------------------------------

subtest 'ir-convert csv to wig' => sub {
    my ($out, $exit) = run_script('ir-convert', '--from', 'csv', '--to', 'wig',
        '--in', $nec_csv, '--name', 'From CLI', '--brand', 'Acme', '--kind', 'tv');
    is($exit, 0, 'exits 0');
    my $wig = json_ok($out, 'wig output');
    return unless $wig;
    is($wig->{format}, 'hair-wig/3', 'hair-wig/3 format');
    is($wig->{name}, 'From CLI', 'name set');
    is(scalar(@{ $wig->{signals} }), 7, '7 NEC buttons');
    is($wig->{origin}, 'converted:ir-convert', 'origin stamp set');
};

subtest 'ir-convert wig to pronto' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $wig_file = File::Spec->catfile($dir, 'in.wig.json');
    my ($wig, $we) = run_script('ir-convert', '--from', 'csv', '--to', 'wig',
        '--in', $jvc_csv, '--name', 'JVC VCR');
    is($we, 0, 'source wig built') or return;
    _slurp_write($wig_file, $wig);

    my ($out, $exit) = run_script('ir-convert', '--from', 'wig', '--to', 'pronto',
        '--in', $wig_file);
    is($exit, 0, 'exits 0');
    my @lines = grep { /\S/ } split /\n/, $out;
    is(scalar(@lines), 5, 'one Pronto line per signal');
    ok(@lines && $lines[0] =~ /^0000 /, 'raw Pronto hex lines');
};

subtest 'ir-convert tasmota to pronto' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $log = File::Spec->catfile($data, 'tasmota-captures.log');
    open my $fh, '<:raw', $log or die "Cannot read $log: $!\n";
    my $line = <$fh>;
    close $fh;
    my $entry = JSON::PP->new->decode($line);
    my $raw = File::Spec->catfile($dir, 'capture.tasmota');
    _slurp_write($raw, $entry->{IrReceived}{RawData});

    my ($out, $exit) = run_script('ir-convert', '--from', 'tasmota',
        '--to', 'pronto', '--in', $raw);
    is($exit, 0, 'exits 0');
    like($out, qr/^0000 /, 'Pronto hex emitted');
};

subtest 'ir-convert pronto to tasmota' => sub {
    my $pronto = pronto_for('NEC', '0x10EF00FF');
    my $pronto_file = File::Spec->catfile(tempdir(CLEANUP => 1), 'nec.pronto');
    _slurp_write($pronto_file, $pronto);

    my ($out, $exit) = run_script('ir-convert', '--from', 'pronto',
        '--to', 'tasmota', '--in', $pronto_file);
    is($exit, 0, 'exits 0');
    like($out, qr/^IRSend /, 'Tasmota IRSend output');
    like($out, qr/\+9020-4520/, 'contains NEC header timings from the source hex');
};

subtest 'ir-convert tasmota structured line to pronto' => sub {
    my $dir  = tempdir(CLEANUP => 1);
    my $file = File::Spec->catfile($dir, 'struct.tasmota');
    _slurp_write($file, "IRrecv: Protocol = NEC, Bits = 32, Data = 0x10EF00FF\n");

    my ($out, $exit) = run_script('ir-convert', '--from', 'tasmota',
        '--to', 'pronto', '--in', $file);
    is($exit, 0, 'exits 0');
    like($out, qr/^0000 006D/, 'Pronto hex with NEC frequency word');
    my @tokens = split /\s+/, $out;
    cmp_ok(scalar(@tokens), '>=', 8, 'Pronto has header + data pairs');
};

subtest 'ir-convert csv to wig with headers' => sub {
    my $dir  = tempdir(CLEANUP => 1);
    my $file = File::Spec->catfile($dir, 'test.csv');
    _slurp_write($file, "protocol,device,subdevice,function\nNEC,4,0,8\nNEC,4,0,9\n");

    my ($out, $exit) = run_script('ir-convert', '--from', 'csv', '--to', 'wig',
        '--in', $file, '--name', 'CLI Test');
    is($exit, 0, 'exits 0');
    my $wig = json_ok($out, 'wig output');
    return unless $wig;
    is(scalar(@{ $wig->{signals} }), 2, 'two CSV rows produce two signals');
    ok($wig->{signals}[0]{pronto} =~ /^0000 /, 'signals carry Pronto hex');
};

subtest 'ir-convert wig to pronto roundtrip' => sub {
    my $dir      = tempdir(CLEANUP => 1);
    my $wig_file = File::Spec->catfile($dir, 'roundtrip.wig.json');
    my $pronto_file = File::Spec->catfile($dir, 'roundtrip.pronto');

    # Build a wig from a known NEC signal (from CSV)
    my $nec_csv = File::Spec->catfile($data, 'irdb-nec-receiver.csv');
    my ($wig_json, $we) = run_script('ir-convert', '--from', 'csv', '--to', 'wig',
        '--in', $nec_csv, '--name', 'RT');
    is($we, 0, 'wig built from CSV') or return;
    _slurp_write($wig_file, $wig_json);

    my ($out, $exit) = run_script('ir-convert', '--from', 'wig', '--to', 'pronto',
        '--in', $wig_file);
    is($exit, 0, 'exits 0');
    my @lines = grep { /\S/ } split /\n/, $out;
    is(scalar(@lines), 7, 'one Pronto line per wig signal');
    ok($lines[0] =~ /^0000 /, 'lines are raw Pronto hex');
};

subtest 'ir-convert tasmota compact to mode2' => sub {
    my $dir  = tempdir(CLEANUP => 1);
    my $file = File::Spec->catfile($dir, 'nec.raw');
    _slurp_write($file, "+9020-4525+550-560+550-560+550-1685+550-560+550-560+550-560+550-560+550-560+550-560+550-560+550-1685+550-1685+550-560+550-1685+550-560+550-560+550-560+550-1685+550-560+550-1685+550-1685+550-1685+550-560+550-1685+550-560+550-1685+550-1685+550-560+550-560+550-560+550-560+550-560+550-1685+550-1685+550-560+550-1685+550-1685+550-1685+550-1685+550-1685+550-1685");

    my ($out, $exit) = run_script('ir-convert', '--from', 'tasmota',
        '--to', 'mode2', '--in', $file);
    is($exit, 0, 'exits 0');
    like($out, qr/^pulse \d+/m, 'mode2 pulse lines');
    like($out, qr/^space \d+/m, 'mode2 space lines');
    my @lines = split /\n/, $out;
    cmp_ok(scalar(@lines), '>=', 10, 'multiple timing lines emitted');
};

subtest 'ir-convert pronto to mode2' => sub {
    my $pronto = pronto_for('NEC', '0x10EF00FF');
    my $dir  = tempdir(CLEANUP => 1);
    my $file = File::Spec->catfile($dir, 'nec.pronto');
    _slurp_write($file, $pronto);

    my ($out, $exit) = run_script('ir-convert', '--from', 'pronto',
        '--to', 'mode2', '--in', $file);
    is($exit, 0, 'exits 0');
    like($out, qr/^pulse 9\d{3}/m, 'mode2 starts with ~9000 µs pulse');
    like($out, qr/^space 4\d{3}/m, 'second line is ~4500 µs space');
};

subtest 'ir-convert mode2 to tasmota' => sub {
    my $dir  = tempdir(CLEANUP => 1);
    my $file = File::Spec->catfile($dir, 'nec.mode2');
    _slurp_write($file, <<'MODE2');
pulse 9020
space 4525
pulse 550
space 560
pulse 550
space 560
pulse 550
space 1685
pulse 550
space 560
pulse 550
space 560
pulse 550
space 560
pulse 550
space 560
pulse 550
space 560
pulse 550
space 560
pulse 550
space 560
pulse 550
space 1685
pulse 550
space 1685
pulse 550
space 560
pulse 550
space 1685
pulse 550
space 560
pulse 550
space 560
pulse 550
space 560
pulse 550
space 1685
pulse 550
space 560
pulse 550
space 1685
pulse 550
space 1685
pulse 550
space 1685
pulse 550
space 560
pulse 550
space 1685
pulse 550
space 560
pulse 550
space 1685
pulse 550
space 1685
pulse 550
space 560
pulse 550
space 560
pulse 550
space 560
pulse 550
space 560
pulse 550
space 560
pulse 550
space 560
pulse 550
space 560
pulse 550
space 560
pulse 550
space 1685
pulse 550
space 1685
pulse 550
space 560
pulse 550
space 1685
pulse 550
space 1685
pulse 550
space 1685
pulse 550
space 1685
pulse 550
space 1685
pulse 550
space 1685
pulse 550
space 43995
MODE2

    my ($out, $exit) = run_script('ir-convert', '--from', 'mode2',
        '--to', 'tasmota', '--in', $file);
    is($exit, 0, 'exits 0');
    like($out, qr/^IRSend /, 'Tasmota IRSend output');
};

subtest 'ir-convert gcir to wig passes unknown protocols through' => sub {
    # Two commands extracted from a real "Eufy 40 Bit" GC export; the
    # workspace sample files are local-only, so the payloads are embedded.
    my $dir = tempdir(CLEANUP => 1);
    my $gc = File::Spec->catfile($dir, 'eufy.gc.json');
    _slurp_write($gc, <<'JSON');
{"commands": [
  {"keycode": "G:Eufy 40 Bit:()(0x68A0000008)():3", "name": "Auto",
   "pronto": "0000 006D 002A 0000 0071 0072 0013 0013 0013 0039 0013 0039 0013 0013 0013 0039 0013 0013 0013 0013 0013 0013 0013 0039 0013 0013 0013 0039 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0039 0013 0013 0013 0013 0013 0013 0013 0304",
   "protocol": "Eufy 40 Bit"},
  {"keycode": "G:Eufy 40 Bit:()(0x68450632E5)():3", "name": "CurrentTime",
   "pronto": "0000 006D 002A 0000 0071 0072 0013 0013 0013 0039 0013 0039 0013 0013 0013 0039 0013 0013 0013 0013 0013 0013 0013 0013 0013 0039 0013 0013 0013 0013 0013 0013 0013 0039 0013 0013 0013 0039 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0013 0039 0013 0039 0013 0013 0013 0013 0013 0013 0013 0039 0013 0039 0013 0013 0013 0013 0013 0039 0013 0013 0013 0039 0013 0039 0013 0039 0013 0013 0013 0013 0013 0039 0013 0013 0013 0039 0013 0304",
   "protocol": "Eufy 40 Bit"}
]}
JSON

    my ($out, $exit) = run_script('ir-convert', '--from', 'gcir', '--to', 'wig',
        '--in', $gc, '--name', 'Eufy Vacuum');
    is($exit, 0, 'exits 0');
    my $wig = json_ok($out, 'wig output');
    return unless $wig;
    is(scalar(@{ $wig->{signals} }), 2, 'both "Eufy 40 Bit" commands converted');
    is($wig->{signals}[0]{alias}, 'Auto', 'first button is Auto');
    like($wig->{signals}[0]{pronto}, qr/^0000 006D 002A/, 'raw Pronto hex carried through');

    my $wig_file = File::Spec->catfile($dir, 'eufy.wig.json');
    _slurp_write($wig_file, $out);
    my ($pr, $pe) = run_script('ir-convert', '--from', 'wig', '--to', 'pronto',
        '--in', $wig_file);
    is($pe, 0, 'wig to pronto exits 0');
    my @lines = grep { /\S/ } split /\n/, $pr;
    is(scalar(@lines), 2, 'one verbatim Pronto line per signal');
};

subtest 'ir-convert usage errors' => sub {
    my ($o1, $e1) = run_script('ir-convert', '--from', 'csv', '--to', 'csv');
    isnt($e1, 0, 'rejects non-exportable --to csv');

    my ($o2, $e2) = run_script('ir-convert');
    isnt($e2, 0, 'missing --from/--to exits non-zero');

    my ($o3, $e3) = run_script('ir-convert', '--from', 'csv', '--to', 'wig',
        '--in', File::Spec->catfile($root, 'does-not-exist.csv'));
    isnt($e3, 0, 'missing input file exits non-zero');
};

done_testing;

sub _slurp {
    my ($file) = @_;
    open my $fh, '<:raw', $file or die "Cannot read $file: $!\n";
    local $/;
    return <$fh>;
}

sub _slurp_write {
    my ($file, $text) = @_;
    open my $fh, '>:raw', $file or die "Cannot write $file: $!\n";
    print {$fh} $text;
    close $fh;
}
