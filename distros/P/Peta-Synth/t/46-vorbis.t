use v5.36;
use Test::More;
use File::Temp qw(tempdir);
use lib 'lib';
use Peta::Vorbis::Encode;
use Peta::Vorbis::Encode::Book;
use Peta::Vorbis::Encode::MDCT;
use Peta::Vorbis::Encode::Ogg;
use Peta::Synth::Output;

use constant PI => 3.141592653589793;

# Codewords as the specification assigns them (its own example).
my $codes = Peta::Vorbis::Encode::Book::_codes([ 2, 4, 4, 4, 4, 2, 3, 3 ]);
is(join(' ', map { sprintf '%0*b', $_->[1], $_->[0] } @$codes), '00 0100 0101 0110 0111 10 110 111', 'codewords as Vorbis assigns them');
for my $x (1, -0.5, 17, -4590, 765) {
    my $p = Peta::Vorbis::Encode::Book::float32($x);
    my $m = $p & 0x1FFFFF;
    $m = -$m if $p & 0x80000000;
    is($m * 2**((($p & 0x7FE00000) >> 21) - 788), $x, "Vorbis float of $x");
}
my $book = Peta::Vorbis::Encode::Book->new(dimensions => 2, values => 9, minimum => -20, delta => 5);
is_deeply([ $book->vector($book->entry(-15, 10)) ], [ -15, 10 ], 'a lattice entry and its values');
my $kraft = 0;
$kraft += 2**-$_ for @{ $book->lengths };
is($kraft, 1, 'the code fills its tree');

# The MDCT through the FFT against its definition.
my $n = 64;
my $mdct = Peta::Vorbis::Encode::MDCT->new($n);
my $w = Peta::Vorbis::Encode::MDCT::window($n);
my @x = map { sin($_ * 0.3) + 0.5 * cos($_ * 1.7) } 0 .. $n - 1;
my $got = $mdct->transform(\@x, $w);
my $worst = 0;
for my $k (0 .. $n / 2 - 1) {
    my $s = 0;
    $s += $x[$_] * $w->[$_] * cos(2 * PI / $n * ($_ + 0.5 + $n / 4) * ($k + 0.5)) for 0 .. $n - 1;
    $worst = abs($s - $got->[$k]) if abs($s - $got->[$k]) > $worst;
}
cmp_ok($worst, '<', 1e-9, 'the MDCT is the MDCT');
SKIP: {
    skip 'no PDL', 2 unless eval { require Peta::Vorbis::Encode::MDCT::PDL; 1 };
    my $pdl = Peta::Vorbis::Encode::MDCT::PDL->new($n);
    my @y = map { cos($_ * 0.9) } 0 .. $n - 1;
    my ($a, $b) = $pdl->transform_all([ \@x, \@y ], $w);
    my $want = $mdct->transform(\@y, $w);
    my $apart = 0;
    for my $k (0 .. $n / 2 - 1) {
        for my $d (abs($a->[$k] - $got->[$k]), abs($b->[$k] - $want->[$k])) { $apart = $d if $d > $apart }
    }
    cmp_ok($apart, '<', 1e-12, 'the PDL MDCT gives the same coefficients, both channels at once');
    is(scalar @$b, $n / 2, 'as many as there should be');
}
my $complement = 0;
$complement = abs($w->[$_]**2 + $w->[ $_ + $n / 2 ]**2 - 1) > $complement ? abs($w->[$_]**2 + $w->[ $_ + $n / 2 ]**2 - 1) : $complement for 0 .. $n / 2 - 1;
cmp_ok($complement, '<', 1e-12, 'the window is power complementary');

# Coupling: what the decoder's four cases make of it is what went in.
my $lost = 0;
for my $l (-12 .. 12) {
    for my $r (-12 .. 12) {
        my @a = ($l);
        my @b = ($r);
        Peta::Vorbis::Encode::_couple(\@a, \@b, 1);
        my ($m, $g) = ($a[0], $b[0]);
        my @back = $m > 0 ? ($g > 0 ? ($m, $m - $g) : ($m + $g, $m)) : ($g > 0 ? ($m, $m + $g) : ($m - $g, $m));
        $lost++ if $back[0] != $l || $back[1] != $r;
    }
}
is($lost, 0, 'coupling loses nothing');

# A stream: its pages read back.
my $rate = 44100;
my @left  = map { 0.5 * sin(2 * PI * 1000 * $_ / $rate) } 0 .. 30000 - 1;
my @right = map { 0.3 * sin(2 * PI * 1500 * $_ / $rate) } 0 .. 30000 - 1;
my $enc = Peta::Vorbis::Encode->new(rate => $rate, channels => 2, quality => 5, serial => 1234);
my $stream = $enc->encode(\@left, \@right) . $enc->finish;
my (@pages, $bad);
my $at = 0;
while ($at < length $stream) {
    my ($magic, $version, $flags, $granule, $serial, $seq, $crc, $segments) = unpack 'a4 C C q< V V V C', substr $stream, $at, 27;
    if ($magic ne 'OggS') { $bad = "no page at $at"; last }
    my @lacing = unpack 'C*', substr $stream, $at + 27, $segments;
    my $body = 0;
    $body += $_ for @lacing;
    my $page = substr $stream, $at, 27 + $segments + $body;
    my $zeroed = $page;
    substr($zeroed, 22, 4) = "\0\0\0\0";
    push @pages, { flags => $flags, granule => $granule, serial => $serial, seq => $seq, crc_ok => $crc == Peta::Vorbis::Encode::Ogg::crc($zeroed),
        first => substr($page, 27 + $segments, 7) };
    $at += length $page;
}
ok(!$bad, 'the stream is pages') or diag $bad;
is((grep { !$_->{crc_ok} } @pages), 0, 'every page\'s CRC holds');
is_deeply([ map { $_->{seq} } @pages ], [ 0 .. $#pages ], 'numbered in order');
is((grep { $_->{serial} != 1234 } @pages), 0, 'one stream');
is($pages[0]{flags}, 2, 'the first page begins the stream');
is($pages[0]{first}, "\x01vorbis", 'with the identification header');
is($pages[-1]{flags} & 4, 4, 'the last page ends it');
is($pages[-1]{granule}, 30000, 'and says how many samples there are');

# Through the writer, and back through FFmpeg where it is.
my $dir = tempdir(CLEANUP => 1);
my $file = "$dir/tone.ogg";
Peta::Synth::Output->write_file($file, \@left, \@right, rate => $rate, quality => 5);
SKIP: {
    skip 'no ffmpeg to decode with', 2 unless Peta::Synth::Output::which('ffmpeg');
    my @back = unpack 'f<*', scalar qx{ffmpeg -v error -i "$file" -f f32le -ac 2 - 2>/dev/null};
    is(scalar @back, 2 * 30000, 'FFmpeg gives back as many samples as were encoded');
    my ($signal, $noise) = (0, 0);
    for my $i (3000 .. 27000) { $signal += $left[$i]**2; $noise += ($left[$i] - $back[ 2 * $i ])**2 }
    cmp_ok(10 * log($signal / $noise) / log(10), '>', 20, 'and the sound, to more than 20 dB');
}

done_testing;
