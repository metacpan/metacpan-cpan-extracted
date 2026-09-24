#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::PP;
use File::Basename qw(dirname);
use File::Spec;
use Protocol::IR::Converter;
use Protocol::IR::Code;

my $converter = Protocol::IR::Converter->new();

# Counters for capture validation, shared with check_capture_line().
our ($decoded, $checked) = (0, 0);

# Decode one JSON IrReceived line, check it against the log's own DataLSB,
# and roundtrip it through both the compact and comma Tasmota styles.
# Lines that do not decode to a known protocol are skipped.
sub check_capture_line {
    my ($line, $label) = @_;
    return unless $line =~ /\{/;
    my $rec;
    eval { $rec = decode_json($line)->{IrReceived}; 1 } or return;

    my $orig = $converter->import_format('Tasmota', $rec->{RawData})->[0];
    return if $orig->protocol eq 'UNKNOWN';
    $decoded++;

    if (defined $rec->{DataLSB}) {
        is($orig->data, hex($rec->{DataLSB}), "$label decoded data matches DataLSB");
    }

    my $via_compact = $converter->import_format('Tasmota',
        $converter->export_code($orig, 'Tasmota'))->[0];
    is($via_compact->protocol, $orig->protocol, "$label compact roundtrip protocol");
    is($via_compact->data,     $orig->data,     "$label compact roundtrip data");

    my $via_comma = $converter->import_format('Tasmota',
        $converter->export_code($orig, 'Tasmota', style => 'comma'))->[0];
    is($via_comma->protocol, $orig->protocol, "$label comma roundtrip protocol");
    is($via_comma->data,     $orig->data,     "$label comma roundtrip data");
    $checked++;
}

# --- compact form decoding ----------------------------------------------
my $compact = "+9185-4490+650-500+655dE-1630C-505+630-525Ed+625-530H-520H-1655JmJiCfCfHmH-1650CfHmHiEdCfCdHiHiEdHiEfCfHiEfEfEfEfC-40270+9160-2235H";
my $code = $converter->import_format('Tasmota', $compact)->[0];
isa_ok($code, 'Protocol::IR::Code');
is($code->protocol, 'NEC',   'compact form decodes to NEC');
is($code->data,     0x04FB09F6, 'compact form yields DataLSB value');
is(ref($code->timings), 'ARRAY', 'timings retained on the code');
is(scalar(@{$code->timings}), 71, '71 timing values from the capture');

# --- comma-separated form ------------------------------------------------
my $comma_in = $converter->import_format('Tasmota', '9185,4490,650,500,655,500,655,1630');
isa_ok($comma_in->[0], 'Protocol::IR::Code', 'comma list decodes');
is($comma_in->[0]->protocol, 'UNKNOWN', 'short comma list is not a full frame');

# --- IRSend command line form --------------------------------------------
my $irsend = "IRsend 38000,9185,4490,650,500,655,500,655,1630";
is($converter->import_format('Tasmota', $irsend)->[0]->protocol,
    'UNKNOWN', 'IRSend frequency prefix is stripped');

# --- protocol-structured lines -------------------------------------------
# In a Tasmota IRrecv line "Data" is IRremoteESP8266's decoded value, which
# for the per-byte LSB-first protocols (NEC) is the accumulated form
# (e.g. 0x08F700FF for address 0x10 / command 0xF7). Import converts it back
# to the display word (0x10EF00FF), matching the JS port.
my $struct = "IRrecv: Protocol = NEC, Bits = 32, Data = 0x08F700FF";
my $s_code = $converter->import_format('Tasmota', $struct)->[0];
is($s_code->protocol, 'NEC',      'structured line decodes by protocol name');
is($s_code->data,     0x10EF00FF, 'structured accumulated Data converts to the display word');
is($s_code->alias,    '0x10EF00FF', 'structured line aliases to the display hex');

# With DataLSB present (the JSON form Tasmota publishes) DataLSB wins for the
# per-byte reversed protocols, so the display hex flows straight through.
my $s_j = q/{"Protocol":"NEC","Bits":32,"Data":"0x08F700FF","DataLSB":"0x10EF00FF"}/;
my $s_j_code = $converter->import_format('Tasmota', $s_j)->[0];
is($s_j_code->data,  0x10EF00FF, 'JSON structured line prefers DataLSB');
is($s_j_code->alias, '0x10EF00FF', 'JSON structured line aliases to DataLSB');

my $s_ts = "17:12:31.456 IRrecv: Protocol = JVC, Bits = 16, Data = 0xC030";
my $s_jvc = $converter->import_format('Tasmota', $s_ts)->[0];
is($s_jvc->protocol, 'JVC',   'timestamp-prefixed structured line decodes');
is($s_jvc->alias,    '0x030C', 'JVC accumulated Data converts to the display hex');

# SAMSUNG JSON: DataLSB is the display hex, Data the accumulated form; the
# converter must keep the DataLSB so the button round-trips (address 0xE0).
my $s_s = q/{"Protocol":"SAMSUNG","Bits":32,"Data":"0xE0E040BF","DataLSB":"0x070702FD"}/;
my $s_s_code = $converter->import_format('Tasmota', $s_s)->[0];
is($s_s_code->protocol, 'SAMSUNG', 'SAMSUNG JSON structured line decodes');
is($s_s_code->address,  224, 'SAMSUNG DataLSB gives the display address 0xE0');
is($s_s_code->data,     0x070702FD, 'SAMSUNG accumulated data word');

# --- MWM bundle records import as the first frame ---------------------------
# A structured MWM record whose Data ingests a whole A+B+A' capture decodes as
# one code, the bundle's first frame -- the decode_raw law mirrored from the
# JS port; the unbundle capability itself is exercised in t/19-mwm.t.
my $bundle_dump = 'IRrecv: Protocol = MWM, Bits = 264, '
    . 'Data = 0x96190B09088418014D9C260CD5636B58EE4803D13C07068596190B09088418014D';
my $bundle_code = $converter->import_format('Tasmota', $bundle_dump)->[0];
isa_ok($bundle_code, 'Protocol::IR::Code', 'bundled MWM record decodes');
is($bundle_code->protocol, 'MWM', 'bundled MWM record protocol');
is($bundle_code->bits, 72, 'bundled MWM record yields the first frame width');
is($bundle_code->data->as_hex, '0x96190b09088418014d',
    'bundled MWM record yields the first frame value');

# --- multi-signal console dump -------------------------------------------
my $dump = <<'DUMP';
17:12:31.100 IRrecv: Protocol = NEC, Bits = 32, Data = 0x10EF00FF
17:12:31.200 IRrecv: RawData = +8495-4070+660-1440C-1450+620-430+655-390H-400+645-405Ci+650jHeCdC-1445+625-425M-1480OjMjCiC
17:12:31.300 IRrecv: Protocol = RC5, Bits = 14, Data = 0x400
17:12:31.400 IRrecv: RawData = +435-1540+440-555C-560+445-540+460-580+415d+430-1570C-1560C-585+420-1550+450-550
17:12:31.500 this is just log noise
IRsend 38000,9185,4490,650,500,655,500,655,1630
DUMP
my $dump_codes = $converter->import_format('Tasmota', $dump);
is(scalar(@$dump_codes), 2, 'dump decodes the supported signals, drops the rest');
is($dump_codes->[0]->protocol, 'NEC',        'dump first signal is structured NEC');
is($dump_codes->[0]->alias,    '0x08F700FF', 'dump NEC alias keeps the accumulated Data hex');
is($dump_codes->[1]->protocol, 'JVC',        'dump second signal is raw JVC data');
is($dump_codes->[1]->alias,    '0x0317',     'dump JVC alias comes from decoded data');

# --- export --------------------------------------------------------------
my $out_compact = $converter->export_code($code, 'Tasmota');
like($out_compact, qr/^IRSend 0,/, 'compact export emits IRSend prefix');
my $body = $out_compact;
$body =~ s/^IRSend \d+,//;
is($body, $compact, 'compact export reproduces the exact input');

my $out_comma = $converter->export_code($code, 'Tasmota', style => 'comma');
like($out_comma, qr/^IRSend 0,9185,4490,650,500,655,500,655,1630/,
    'comma export emits a numeric list');

my $out_freq = $converter->export_code($code, 'Tasmota', style => 'comma', frequency => 38000);
like($out_freq, qr/^IRSend 38000,9185/, 'explicit frequency carried into export');

my $back = $converter->import_format('Tasmota', $out_comma)->[0];
is($back->protocol, $code->protocol, 'comma export re-imports');
is($back->data,     $code->data,     'comma export preserves data');

# --- raw / UNKNOWN captures ----------------------------------------------
# Unknown captures keep their timing data so they can be re-emitted verbatim.
my $raw = "+435-1540+440-555C-560+445-540+460-580+415d+430-1570C-1560C-585+420-1550+450-550";
my $raw_code = $converter->import_format('Tasmota', $raw)->[0];
is($raw_code->protocol, 'UNKNOWN', 'unmatched signal is tagged UNKNOWN');
my $raw_out = $converter->export_code($raw_code, 'Tasmota');
$raw_out =~ s/^IRSend \d+,//;
is($raw_out, $raw, 'UNKNOWN timing data roundtrips verbatim');

# --- bundled capture fixture ---------------------------------------------
# Every frame in t/data/tasmota-captures.log must survive a compact and a
# comma export/import roundtrip without changing protocol or data.
my $fixture = File::Spec->rel2abs(File::Spec->catfile(
    dirname(__FILE__), 'data', 'tasmota-captures.log'));
ok(-e $fixture, 't/data/tasmota-captures.log present');

open my $fh, '<', $fixture or die "Cannot open $fixture: $!\n";
my $line_no = 0;
while (my $line = <$fh>) {
    $line_no++;
    check_capture_line($line, "fixture line $line_no");
}
close $fh;
cmp_ok($decoded, '>=', 11, 'decoded the bundled capture frames');
cmp_ok($checked, '>=', 11, 'roundtripped the bundled capture frames');

# --- live wide-protocol captures -----------------------------------------
# Signals encoded by our own protocol encoders, transmitted over the MQTT IR
# test rig (Tasmota IRsend raw) and captured back. IRremoteESP8266 natively
# decodes SAMSUNG36 (Data=0x7004E50F3) but has no native decoder for the
# 48-NEC1/JVC-48/SAMSUNG20 frames, so the RawData timing decode must recover
# the transmitted address/subaddress/command.
my @wide_captures = (
    [ 'SAMSUNG36',  '{"Protocol":"SAMSUNG36","Bits":36,"Data":"0x7004E50F3","DataLSB":"0xE000720ACF","Repeat":0,"RawData":"+4545-4430+535-470C-1450+540-1440CeFdFd+530-475FdCdCdCdFiCiF-1445HiCdF-4420FgCjCgFdHdFgFdFjCdCdFdF-465FgFgFjFgFdCdFgFgF","RawDataInfo":[77,77,0]}',
      'SAMSUNG36', 0x7004, -1, 0xE50F3 ],
    [ '48-NEC1',    '{"Protocol":"MIDEA24","Bits":24,"Data":"0xB21600","DataLSB":"0x4D6800","Repeat":0,"RawData":"+9010-4490+535-1705+540-575+590-1650CdEf+585-525I-1655IjIjIhEfG-520GhEdEfGhCfGjIjIkEfIhGhE-580IkIkIkCfGhEfGlGhIjGlGlGlGlGlGlGjIh+560-1680EdCdEdEdNoNoE","RawDataInfo":[99,99,0]}',
      '48-NEC1', 77, 178, 104 ],
    [ 'JVC-48',     '{"Protocol":"PANASONIC","Bits":48,"Data":"0xC0804484C000","DataLSB":"0x30122210300","Repeat":0,"RawData":"+3470-1720+460-1280+455dE-420+450fE-415EhEfEhEdEfC-410CiCfEhEhEfGhCdEfEhEhEdGfEhEdEhEfEhEhEdGfGfEdEdCiCfEhEhChEfEhEhCiChEfGfGfGfE","RawDataInfo":[99,99,0]}',
      'JVC-48', 34, 33, 3 ],
    [ 'SAMSUNG20',  '{"Protocol":"UNKNOWN","Bits":22,"Hash":"0xFA37F15D","Repeat":0,"RawData":"+4530-4495+595-1680C-555+560cEcFcF-590Fc+580-575FcE-1720CeFgFjCdC-1675+600-550FcEjCeHiF","RawDataInfo":[43,43,0]}',
      'SAMSUNG20', 1, 8, 39 ],
);
for my $cap (@wide_captures) {
    my ($label, $json, $proto, $addr, $sub, $cmd) = @$cap;
    my $rec = decode_json($json);

    my $via_timing = $converter->import_format('Tasmota', $rec->{RawData})->[0];
    is($via_timing->protocol,   $proto, "$label RawData decodes to the protocol");
    is($via_timing->address,    $addr,  "$label RawData decodes to the address");
    is($via_timing->subaddress, $sub,   "$label RawData decodes to the subaddress");
    is($via_timing->command,    $cmd,   "$label RawData decodes to the command");

    my $reenc = $converter->export_code($via_timing, 'Tasmota');
    $reenc =~ s/^IRSend \d+,//;
    is($reenc, $rec->{RawData}, "$label compact roundtrip is byte-identical");

    if ($proto eq 'SAMSUNG36') {
        my $via_struct = $converter->import_format('Tasmota',
            'Protocol = SAMSUNG36, Bits = 36, Data = 0x7004E50F3')->[0];
        is($via_struct->data, hex('0x7004E50F3'), "$label structured Data decode");
    }
}

# --- optional user-provided samples --------------------------------------
# If the user drops a Tasmota IR log in samples/, validate it too. No minimum
# is asserted: the file is optional and may contain anything.
my $samples_dir = File::Spec->rel2abs(File::Spec->catdir(
    dirname(__FILE__), '..', 'samples'));
my @sample_logs = glob(File::Spec->catfile($samples_dir, 'tasmota*.log'));
if (@sample_logs) {
    for my $log (sort @sample_logs) {
        (my $base = $log) =~ s/.*\///;
        open my $sfh, '<', $log or next;
        my $n = 0;
        while (my $line = <$sfh>) {
            $n++;
            check_capture_line($line, "$base line $n");
        }
        close $sfh;
        pass("validated optional sample log $base");
    }
} else {
    pass('no optional samples/ log present; skipping');
}

# --- error handling ------------------------------------------------------
eval { $converter->import_format('Tasmota', '') };
like($@, qr/unrecognized tasmota rawdata/i, 'rejects empty input');

eval { $converter->import_format('Tasmota', '12345') };
like($@, qr/unrecognized tasmota rawdata/i, 'rejects unrecognized input');

eval { $converter->import_format('Tasmota', '+100-100Z') };
like($@, qr/undefined timing letter/i, 'rejects unknown letter in compact form');

eval { $converter->export_code(Protocol::IR::Code->new(protocol => 'UNKNOWN'), 'Tasmota') };
like($@, qr/no protocol encoder/i,
    'rejects export of a code with no timings and no encodable protocol');

eval { $converter->export_code($code, 'Tasmota', style => 'xml') };
like($@, qr/unsupported tasmota export style/i, 'rejects unknown export style');

done_testing;
