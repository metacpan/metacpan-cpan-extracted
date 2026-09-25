#!/usr/bin/env perl
use strict;
use warnings;
no warnings 'portable';
use Test::More;
use File::Basename qw(dirname);
use File::Spec;
use Protocol::IR::Converter;
use Protocol::IR::Code;

# Mode2 pulse/space capture format, the native format of the LIRC `mode2`
# tool and the MQTT IR test rig's receiver topic ("hear back timings"): one
# timing per line, "pulse N" or "space N", in microseconds, strictly
# alternating. Messages split on a space of 10000 µs or more (lirc's default
# inter-message gap).

my $converter = Protocol::IR::Converter->new();

# --- decoding a multi-message capture --------------------------------------
my $fixture = File::Spec->rel2abs(File::Spec->catfile(
    dirname(__FILE__), 'data', 'mode2-capture.log'));
ok(-e $fixture, 't/data/mode2-capture.log present');
open my $fh, '<', $fixture or die "Cannot open $fixture: $!\n";
local $/; my $text = <$fh>;
close $fh;

my $codes = $converter->import_format('Mode2', $text);
is(scalar(@$codes), 156, '156 messages decoded');

my %counts;
for my $code (@$codes) { $counts{$code->protocol}++; }
is_deeply(\%counts, {
    SAMSUNG   => 30,
    JVC       => 11,
    UNKNOWN   => 55,
    NEC       => 28,
    SAMSUNG36 => 11,
    MWM       => 21,
}, 'protocol distribution matches the reference decode');

my %widths;
for my $code (@$codes) {
    $widths{$code->bits}++ if $code->protocol eq 'MWM';
}
is_deeply(\%widths, { 72 => 14, 96 => 2, 104 => 1, 112 => 2, 120 => 2 },
    'MWM frame widths');

# Every code keeps its raw timings; the identified MWM signals carry a full
# frame (the short UNKNOWN fragments are noise captures).
my $all_timed = 1;
for my $code (@$codes) {
    $all_timed = 0 unless $code->timings && @{$code->timings} >= 2;
}
ok($all_timed, 'every code keeps its raw timings');
my $mwm_all_full = 1;
for my $code (@$codes) {
    $mwm_all_full = 0 if $code->protocol eq 'MWM' && @{$code->timings} < 30;
}
ok($mwm_all_full, 'MWM signals carry a full frame of timings');

# --- export to re-import roundtrips every code -------------------------------
my $re = $converter->import_format('Mode2',
    $converter->export_codes('Mode2', $codes));
is(scalar(@$re), scalar(@$codes), 're-import returns the same message count');
my $mwm = [ grep { $_->protocol eq 'MWM' } @$codes ];
my $re_mwm = [ grep { $_->protocol eq 'MWM' } @$re ];
is(scalar(@$re_mwm), scalar(@$mwm), 'all MWM signals survive the roundtrip');
my $preserved = 1;
for my $m (@$mwm) {
    my $found = grep { $_->data eq $m->data && $_->bits == $m->bits } @$re_mwm;
    $preserved = 0 unless $found;
}
ok($preserved, 'each MWM signal re-imports to the same data and bits');

# --- export writes alternating pulse/space lines ending on a wide space ------
my $code = $converter->import_code('MWM', '0x550808');
my $out = $converter->export_code($code, 'Mode2');
my @lines = split /\n/, $out;
ok(scalar(@lines) >= 2, 'export produces multiple lines');
for my $i (0 .. $#lines) {
    like($lines[$i], qr/^(pulse|space) \d+$/, "line $i is a pulse/space pair");
    is($lines[$i] =~ /^pulse/, $i % 2 == 0, "line $i strictly alternates");
}
my $last_space = $lines[-1] =~ /^space (\d+)$/ ? $1 : 0;
ok($last_space >= 10000, 'trailing space splits the message on re-import');

my $back = $converter->import_format('Mode2', $out)->[0];
is($back->protocol, 'MWM', 're-import identifies MWM');
is($back->bits, 24, 're-import preserves bits');
is($back->data->as_hex, '0x550808', 're-import preserves data');

# --- codes without timings derive them from the protocol encoder --------------
my $nec = $converter->import_code('NEC', '0x10EF00FF');
my $nec_out = $converter->export_code($nec, 'Mode2');
my $nec_back = $converter->import_format('Mode2', $nec_out)->[0];
is($nec_back->protocol, 'NEC', 'Pronto-derived Mode2 export decodes to NEC');
is($nec_back->data, 0x10EF00FF, 'Pronto-derived Mode2 export preserves data');

# --- UNKNOWN signals are preserved rather than dropped ------------------------
my $capture = join("\n", 'pulse 4000', 'space 2000', 'pulse 500', 'space 100000');
my $unknown = $converter->import_format('Mode2', $capture)->[0];
is($unknown->protocol, 'UNKNOWN', 'unrecognized signal is kept as UNKNOWN');
is(scalar(@{$unknown->timings}), 4, 'UNKNOWN signal keeps its timings');

# --- dead air between doubled separators is dropped ---------------------------
my $dead_air = join("\n", 'pulse 4000', 'space 100000', 'space 100000', 'pulse 4000');
my $dead_codes = $converter->import_format('Mode2', $dead_air);
is(scalar(@$dead_codes), 2, 'the mark-less gap between separators is dropped');

# --- empty and unparseable input die ------------------------------------------
eval { $converter->import_format('Mode2', undef) };
like($@, qr/No Mode2 capture/, 'undef input dies');
eval { $converter->import_format('Mode2', "hello world\n") };
like($@, qr/No Mode2 timings/, 'input with no timings dies');

done_testing;
