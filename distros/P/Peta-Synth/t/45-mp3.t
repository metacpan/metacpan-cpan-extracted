use v5.36;
use Test::More;
use File::Temp qw(tempdir);
use lib 'lib';
use Peta::MP3::Encode;
use Peta::Synth::Output;

use constant PI => 3.141592653589793;

my $dir = tempdir(CLEANUP => 1);

# The frames of an MP3 stream read back: header, side information, where
# the main data begins and how many bits it has.
sub frames ($bytes) {
    my @frames;
    my $at = 0;
    while ($at + 4 <= length $bytes) {
        my ($h) = unpack 'N', substr $bytes, $at, 4;
        return { error => sprintf('no sync at byte %d', $at) } if ($h >> 21) != 0x7FF;
        my %f = (at => $at, index => ($h >> 12) & 15, rate => ($h >> 10) & 3, padding => ($h >> 9) & 1,
                 mode => ($h >> 6) & 3, extension => ($h >> 4) & 3, lsf => ($h >> 19) & 1 ? 0 : 1);
        my $lsf  = $f{lsf};
        my $kbps = ($lsf ? \@Peta::MP3::Encode::Tables::LSF_BITRATES : \@Peta::MP3::Encode::Tables::BITRATES)->[ $f{index} ];
        $f{hz}   = ($lsf ? [ 22050, 24000, 16000 ] : [ 44100, 48000, 32000 ])->[ $f{rate} ];
        $f{size} = int(($lsf ? 72000 : 144000) * $kbps / $f{hz}) + $f{padding};
        my $channels = $f{mode} == 3 ? 1 : 2;
        my $sidelen = $lsf ? ($channels == 1 ? 9 : 17) : ($channels == 1 ? 17 : 32);
        my $side = unpack 'B*', substr $bytes, $at + 4, $sidelen;
        my $pos = 0;
        my $take = sub ($n) { my $v = oct('0b' . substr($side, $pos, $n)); $pos += $n; $v };
        $f{main_data_begin} = $take->($lsf ? 8 : 9);
        $take->($lsf ? $channels : $channels == 1 ? 5 : 3);
        if (!$lsf) { $f{scfsi} += $take->(4) for 1 .. $channels }
        for my $gr ($lsf ? 0 : (0, 1)) {
            for my $ch (1 .. $channels) {
                my $bits = $take->(12);
                my $big  = $take->(9);
                $f{bits} += $bits;
                $f{big} = $big if $big > ($f{big} // 0);
                $take->($_) for $lsf ? (8, 9, 1, 15, 4, 3, 2) : (8, 4, 1, 15, 4, 3, 3);    # gain .. count1table
            }
        }
        $f{room} = $f{size} - 4 - $sidelen;
        push @frames, \%f;
        $at += $f{size};
    }
    return { error => 'a frame cut short' } if $at != length $bytes;
    return { frames => \@frames };
}

sub tone ($n, $hz, $level, $rate = 44100) { return [ map { $level * sin(2 * PI * $hz * $_ / $rate) } 0 .. $n - 1 ] }

# A stereo tone in joint stereo: the frames are whole, their main data
# within the reservoir's reach, the bits where the side information says.
my $encoder = Peta::MP3::Encode->new(rate => 44100, channels => 2, bitrate => 128);
my $n = 30000;
my $stream = $encoder->encode(tone($n, 440, 0.5), tone($n, 660, 0.3)) . $encoder->finish;
my $read = frames($stream);
ok(!$read->{error}, 'the stream reads back') or diag $read->{error};
my @frames = @{ $read->{frames} // [] };
is(scalar @frames, $encoder->frames, 'as many frames as encoded');
cmp_ok(scalar @frames, '>=', $n / 1152, 'enough frames for the samples');
is((grep { $_->{index} != 9 || $_->{rate} != 0 } @frames), 0, 'every frame 128 kbit/s at 44.1 kHz');
is((grep { $_->{mode} != 1 } @frames), 0, 'joint stereo');
my ($over, $unreachable) = (0, 0);
my $free = 0;    # main data room the frames before have left
for my $f (@frames) {
    $unreachable++ if $f->{main_data_begin} > 511 || $f->{main_data_begin} > $free;
    $over++ if $f->{bits} > 8 * ($f->{main_data_begin} + $f->{room});
    $free = $f->{main_data_begin} + $f->{room} - int(($f->{bits} + 7) / 8);
}
is($unreachable, 0, 'main data never begins further back than there is room');
is($over, 0, 'main data always fits');

# The Info frame: what a decoder needs for gapless playback.
my $info = $encoder->info_frame;
is(length $info, int(144000 * 128 / 44100), 'the Info frame is a frame');
like($info, qr/\A\xFF\xFB.{34}Info/s, 'with the Info tag where it belongs');
my ($frames_in_tag, $bytes_in_tag) = unpack 'N N', substr $info, 44, 8;
is($frames_in_tag, scalar @frames, 'it counts the frames');
is($bytes_in_tag, length($stream) + length($info), 'and the bytes');
my ($delays) = unpack 'N', "\0" . substr $info, 36 + 120 + 21, 3;
is($delays >> 12, 528, 'the encoder delay');
is(($delays & 4095) + 528 + $n, 1152 * @frames, 'the padding at the end');
is(substr($info, 156, 9), 'PetaMP3  ', 'the encoder named');
my $gapless = Peta::MP3::Encode->new(rate => 44100, bitrate => 128, ffmpeg_gapless => 1);
is(substr($gapless->info_frame, 156, 9), 'LavfPeta ', 'with ffmpeg_gapless, a name FFmpeg takes the delay from');

# Silence takes no bits; mono is mono.
my $quiet = Peta::MP3::Encode->new(rate => 48000, channels => 1, bitrate => 64);
my $silent = frames($quiet->encode([ (0.0) x 5000 ]) . $quiet->finish);
ok(!$silent->{error}, 'silence reads back');
is((grep { $_->{bits} } @{ $silent->{frames} }), 0, 'silence takes no bits');
is((grep { $_->{mode} != 3 } @{ $silent->{frames} }), 0, 'mono');

# The filterbanks in Perl and in PDL give the same stream, short blocks
# and all (clicks make some).
SKIP: {
    skip 'no PDL', 2 unless eval { require Peta::MP3::Encode::Filterbank::PDL; 1 };
    my @clicks = map { $_ % 3000 < 3 ? 0.8 : 0.1 * sin($_ * 0.05) } 0 .. 20000;
    my @streams = map {
        my $e = Peta::MP3::Encode->new(rate => 48000, channels => 1, bitrate => 96, filterbank => $_);
        [ $e->encode(\@clicks) . $e->finish, $e->shorts ];
    } qw(perl pdl);
    cmp_ok($streams[0][1], '>', 0, 'clicks are coded in short blocks');
    ok($streams[0][0] eq $streams[1][0], 'the Perl and the PDL filterbank give the same stream');
}

# Variable bitrate: silence, then a tone with noise. The frames' sizes
# follow what they hold; the tag is Xing, its seek table rising.
{
    srand 1;
    my @quiet = (0.0) x 22050;
    my @busy  = map { 0.4 * sin(2 * PI * 440 * $_ / 44100) + 0.1 * (rand() - 0.5) } 0 .. 44099;
    my $vbr = Peta::MP3::Encode->new(rate => 44100, channels => 2, vbr => 2);
    my $s = $vbr->encode([ @quiet, @busy ], [ @quiet, @busy ]) . $vbr->finish;
    my $back = frames($s);
    ok(!$back->{error}, 'a VBR stream reads back') or diag $back->{error};
    my @f = @{ $back->{frames} // [] };
    my %index = map { $_->{index} => 1 } @f;
    cmp_ok(scalar keys %index, '>', 1, 'its frames have more than one bitrate');
    cmp_ok($f[1]{index}, '<', $f[-3]{index}, 'silence in smaller frames than sound');
    is((grep { $_->{main_data_begin} > 511 } @f), 0, 'main data within the reservoir\'s reach');
    cmp_ok((grep { $_->{scfsi} } @f), '>', 0, "the steady tone's scalefactors reused by second granules (scfsi)");
    my $info = $vbr->info_frame;
    like($info, qr/\A\xFF\xFB.{34}Xing/s, 'a Xing tag');
    my @toc = unpack 'C100', substr $info, 4 + 32 + 16, 100;
    is((grep { $toc[$_] < $toc[ $_ - 1 ] } 1 .. 99), 0, 'its seek table rising');
    cmp_ok($toc[50], '<', 128, 'the quiet half taking less than half the bytes');
    cmp_ok(abs($vbr->bitrate - 8 * length($s) / ($vbr->frames * 1152 / 44100) / 1000), '<', 0.01, 'bitrate: the average');
}

# MPEG-2 at its three rates: frames of 576 samples, the reservoir reaching
# 255 bytes; mono, VBR and short blocks too.
for my $rate (22050, 24000, 16000) {
    my $e = Peta::MP3::Encode->new(rate => $rate, channels => 2, bitrate => 64);
    my $s = $e->encode(tone($rate, 440, 0.5, $rate), tone($rate, 660, 0.3, $rate)) . $e->finish;
    my $back = frames($s);
    ok(!$back->{error}, "MPEG-2 at $rate Hz reads back") or diag $back->{error};
    my @f = @{ $back->{frames} // [] };
    ok(@f && !grep({ !$_->{lsf} || $_->{hz} != $rate } @f), '  its frames say MPEG-2 and the rate');
    is(scalar @f, $e->frames, '  as many frames as encoded');
    cmp_ok($e->frames, '>=', $rate / 576, '  of 576 samples each');
    is((grep { $_->{main_data_begin} > 255 } @f), 0, '  main data within 255 bytes back');
}
{
    my $mono = Peta::MP3::Encode->new(rate => 24000, channels => 1, bitrate => 32);
    my $back = frames($mono->encode(tone(24000, 300, 0.5, 24000)) . $mono->finish);
    ok(!$back->{error}, 'MPEG-2 mono reads back');
    my $vbr = Peta::MP3::Encode->new(rate => 22050, channels => 2, vbr => 4);
    my $s = $vbr->encode(tone(22050, 440, 0.5, 22050), tone(22050, 550, 0.4, 22050)) . $vbr->finish;
    ok(!frames($s)->{error}, 'MPEG-2 VBR reads back');
    like($vbr->info_frame, qr/\A\xFF\xF3.{19}Xing/s, '  its Xing tag after the 17 bytes of side information');
    my @clicks = map { $_ % 4000 < 30 ? 0.8 * sin($_) : 0.0 } 0 .. 15999;
    my $c = Peta::MP3::Encode->new(rate => 16000, channels => 1, bitrate => 48);
    ok(!frames($c->encode(\@clicks) . $c->finish)->{error} && $c->shorts > 0, 'MPEG-2 short blocks');
}

ok(!eval { Peta::MP3::Encode->new(rate => 11025) }, 'MPEG-2.5 rates are refused');
ok(!eval { Peta::MP3::Encode->new(rate => 22050, bitrate => 192) }, 'and bitrates MPEG-2 has not');
ok(!eval { Peta::MP3::Encode->new(vbr => 10) }, 'and VBR levels beyond 9');
ok(!eval { Peta::MP3::Encode->new(bitrate => 100) }, 'and bitrates that are not');

# Through the writer of Peta::Synth::Output, and back through a decoder
# where there is one: the same sound, the same length.
my $file = "$dir/tone.mp3";
my $left = tone(44100, 1000, 0.5);
Peta::Synth::Output->write_file($file, $left, tone(44100, 1500, 0.4), rate => 44100, quality => 192);
ok(-s $file, 'an MP3 file written');
my $decoder = Peta::Synth::Output::which('mpg123');
Peta::Synth::Output->write_file("$dir/vbr.mp3", $left, tone(44100, 1500, 0.4), rate => 44100, quality => 'V3');
Peta::Synth::Output->write_file("$dir/lsf.mp3", tone(22050, 700, 0.5, 22050), tone(22050, 900, 0.4, 22050), rate => 22050);
SKIP: {
    skip 'no mpg123 to decode with', 4 unless $decoder;
    my @vbr = unpack 'f<*', scalar qx{mpg123 -q -e f32 -s "$dir/vbr.mp3" 2>/dev/null};
    is(scalar @vbr, 2 * 44100, 'and from a VBR file (quality V3)');
    my @lsf = unpack 'f<*', scalar qx{mpg123 -q -e f32 -s "$dir/lsf.mp3" 2>/dev/null};
    is(scalar @lsf, 2 * 22050, 'and from an MPEG-2 file (22.05 kHz)');
    my $raw = qx{mpg123 -q -e f32 -s "$file" 2>/dev/null};
    my @back = unpack 'f<*', $raw;
    is(scalar @back, 2 * 44100, 'mpg123 gives back as many samples as were encoded');
    my ($signal, $noise) = (0, 0);
    for my $i (2000 .. 42000) {
        $signal += $left->[$i]**2;
        $noise  += ($left->[$i] - $back[ 2 * $i ])**2;
    }
    cmp_ok(10 * log($signal / $noise) / log(10), '>', 40, 'and the sound, to more than 40 dB');
}

done_testing;
