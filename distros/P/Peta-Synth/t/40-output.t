use v5.36;
use Test::More;
use File::Temp qw(tempdir);
use lib 'lib';
use Peta::Synth::Output;
use Peta::Synth::Output::FLAC;

my $dir = tempdir(CLEANUP => 1);
my $n = 10_000;
my @left  = map { 0.5 * sin($_ * 0.05) } 0 .. $n - 1;
my @right = map { 0.25 * sin($_ * 0.031) + ($_ % 7 == 0 ? 0.1 : 0) } 0 .. $n - 1;

sub slurp ($file) { open my $fh, '<:raw', $file or die; local $/; return scalar <$fh> }

# WAV: the header, and the samples (16 bits dithered: within a step).
my $wav = Peta::Synth::Output->write_file("$dir/t.wav", \@left, \@right, rate => 44100);
my $bytes = slurp($wav);
my ($riff, $size, $wave, $fmt, $flen, $pcm, $ch, $rate, undef, $block, $bits, $data, $dlen) =
    unpack 'a4 V a4 a4 V v v V V v v a4 V', $bytes;
is_deeply([ $riff, $wave, $pcm, $ch, $rate, $bits, $data ], [ 'RIFF', 'WAVE', 1, 2, 44100, 16, 'data' ], 'WAV header');
is($dlen, 4 * $n, 'WAV data size');
my @samples = unpack 's<*', substr($bytes, 44);
my $off = 0;
for my $i (0 .. $n - 1) {
    my $d = abs($samples[ 2 * $i ] - $left[$i] * 32767);
    $off = $d if $d > $off;
}
cmp_ok($off, '<=', 2, 'WAV samples within the dither');

my $float = slurp(Peta::Synth::Output->write_file("$dir/f.wav", \@left, \@right, rate => 44100, bits => 32));
my @floats = unpack 'f<*', substr($float, 44);
cmp_ok(abs($floats[200] - $left[100]), '<', 1e-6, '32-bit WAV holds the floats');

# Clipping.
my $loud = slurp(Peta::Synth::Output->write_file("$dir/c.wav", [ 2, -2 ], [ 0, 0 ], rate => 8000));
my @clipped = unpack 's<*', substr($loud, 44);
ok($clipped[0] >= 32766 && $clipped[2] <= -32767, 'out of range is clipped');

# FLAC: the checksums against known values, and a file a decoder accepts.
is(Peta::Synth::Output::FLAC::crc8("123456789"), 0xf4, 'CRC-8 of FLAC');
is(Peta::Synth::Output::FLAC::crc16("123456789"), 0xfee8, 'CRC-16 of FLAC');

for my $depth (16, 24) {
    my $file = Peta::Synth::Output->write_file("$dir/t$depth.flac", \@left, \@right, rate => 44100, bits => $depth);
    my $flac = slurp($file);
    is(substr($flac, 0, 4), 'fLaC', "$depth-bit FLAC marker");
    my $info = substr($flac, 8, 18);
    my ($high, $low) = unpack 'N N', substr($info, 10, 8);
    is($low, $n, "$depth-bit FLAC: STREAMINFO counts the samples");
    cmp_ok(length $flac, '<', $n * 2 * $depth / 8, "$depth-bit FLAC is smaller than its samples");
    SKIP: {
        skip 'no flac program to check the file with', 1 unless Peta::Synth::Output::which('flac');
        is(system('flac', '-s', '-t', $file), 0, "$depth-bit FLAC: the reference decoder finds it sound (CRCs and MD5)");
    }
}

# The compression levels: each sound, none larger than a lower one.
my %size;
for my $level (0, 5, 8) {
    my $file = Peta::Synth::Output->write_file("$dir/l$level.flac", \@left, \@right, rate => 44100, bits => 16, quality => $level);
    $size{$level} = -s $file;
    SKIP: {
        skip 'no flac program to check the file with', 1 unless Peta::Synth::Output::which('flac');
        is(system('flac', '-s', '-t', $file), 0, "FLAC level $level: sound");
    }
}
ok($size{8} <= $size{5} && $size{5} <= $size{0}, "higher levels, smaller files ($size{0}, $size{5}, $size{8} bytes)");
ok(!eval { Peta::Synth::Output->open("$dir/x.flac", quality => 9) }, 'a level above 8 is refused');

like(Peta::Synth::Output::format_of('x.OGG'), qr/ogg/, 'the format from the extension');
ok(!eval { Peta::Synth::Output::format_of('x.xyz') }, 'an unknown extension dies');

done_testing;
