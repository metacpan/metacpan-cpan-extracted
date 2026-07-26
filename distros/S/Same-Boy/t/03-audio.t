#!perl
use 5.008003;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Same::Boy;
use TestROM qw(minimal_rom);

plan tests => 6;

my $gb = Same::Boy->new(model => 'cgb', rom => \minimal_rom());

# No capture until a sample rate is set.
$gb->run_frame;
is(length($gb->samples), 0, 'no audio captured before set_sample_rate');

$gb->set_sample_rate(44100);
$gb->set_highpass_filter('accurate');

$gb->run_frame for 1 .. 5;
my $audio = $gb->samples;
cmp_ok(length($audio), '>', 0, 'audio captured after enabling');
is(length($audio) % 4, 0, 'audio length is a multiple of 4 (s16 stereo)');

# ~44100 Hz over 5 frames (~5/59.7s) => a few thousand stereo frames.
my $frames = length($audio) / 4;
cmp_ok($frames, '>', 1000, "captured plausible sample count ($frames frames)");

# Draining resets the buffer.
is(length($gb->samples), 0, 'samples() drains the capture buffer');

# Disabling stops capture.
$gb->set_sample_rate(0);
$gb->run_frame for 1 .. 3;
is(length($gb->samples), 0, 'no capture after set_sample_rate(0)');
