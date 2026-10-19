package AudioReference;

# The audio references in t/audio-reference: every General MIDI program and
# every drum of the kit, alone, one note each, as WAV (mono, 16 bits).
# devbin/audio-reference writes them; t/34-reference.t renders the same
# notes and compares what it hears with them.
#
# Each note is rendered by a synthesizer of its own (the voices' seeds count
# the notes a synthesizer has started), without reverb or limiter: the
# instrument and nothing else. Left and right are mixed to one.

use v5.36;
use Peta::Synth::Synth;
use Peta::Synth::Patch;

our $DIR      = 't/audio-reference';
our $RATE     = 24000;
my $PARTIALS  = 48;
my $GAIN      = 1;      # the master's
my $KEY       = 60;     # every program plays middle C
my $VELOCITY  = 100;
my $HOLD      = 0.3;    # seconds the key is held
my $LENGTH    = 0.5;    # seconds rendered: the attack, and the beginning of the release
my $FRAME     = 240;    # 10 ms, the frames the levels are compared in

# What is rendered: [file, channel, program, key].
sub items () {
    my $name = sub ($text) { lc($text) =~ s/[^a-z0-9]+/-/gr =~ s/^-|-$//gr };
    return (
        (map { [ sprintf('%03d-%s.wav', $_, $name->(Peta::Synth::Patch::program_name($_))), 0, $_, $KEY ] } 0 .. 127),
        (map { [ sprintf('drum-%02d-%s.wav', $_, $name->(Peta::Synth::Patch::drum_name($_))), 9, undef, $_ ] }
            sort { $a <=> $b } keys %{ Peta::Synth::Patch::drum_names() }),
    );
}

# The note, rendered by the engine given: 16-bit samples, as a WAV holds them.
sub render ($engine, $item) {
    my (undef, $channel, $program, $key) = @$item;
    my $synth = Peta::Synth::Synth->new(rate => $RATE, partials => $PARTIALS, gain => $GAIN, limiter => 0, engine => $engine,
        waves => 1);     # every engine reads the same tables
    $synth->schedule([
        { time => 0, type => 'controller', channel => $channel, number => 91, value => 0 },
        defined $program ? { time => 0, type => 'program', channel => $channel, program => $program } : (),
        { time => 0,     type => 'note_on',  channel => $channel, key => $key, velocity => $VELOCITY },
        { time => $HOLD, type => 'note_off', channel => $channel, key => $key },
    ]);
    my ($left, $right) = $synth->render_frames(int($LENGTH * $RATE + 0.5));
    return [ map { my $x = ($left->[$_] + $right->[$_]) / 2 * 32767;
        $x > 32767 ? 32767 : $x < -32768 ? -32768 : int($x + ($x < 0 ? -0.5 : 0.5)) } 0 .. $#$left ];
}

sub write_wav ($file, $samples) {
    my $bytes = 2 * @$samples;
    open my $fh, '>:raw', $file or die "cannot write '$file': $!\n";
    print {$fh} pack('a4 V a4', 'RIFF', 36 + $bytes, 'WAVE'),
        pack('a4 V v v V V v v', 'fmt ', 16, 1, 1, $RATE, 2 * $RATE, 2, 16),
        pack('a4 V', 'data', $bytes), pack('s<*', @$samples);
    close $fh or die "cannot write '$file': $!\n";
}

# The samples of a WAV that write_wav wrote; dies on any other.
sub read_wav ($file) {
    open my $fh, '<:raw', $file or die "cannot read '$file': $!\n";
    my $data = do { local $/; <$fh> };
    my ($riff, $wave, $fmt, $format, $channels, $rate, $bits, $tag, $bytes) = unpack 'a4 x4 a4 a4 x4 v v V x6 v a4 V', $data;
    die "$file: not a mono 16-bit WAV at $RATE Hz\n"
        unless $riff eq 'RIFF' && $wave eq 'WAVE' && $fmt eq 'fmt ' && $format == 1 && $channels == 1
            && $rate == $RATE && $bits == 16 && $tag eq 'data' && $bytes == length($data) - 44;
    return [ unpack 's<*', substr $data, 44 ];
}

# How like the reference a sound is. snr: the reference's energy over that
# of the difference, in dB (inf when they are the same); level: the
# loudness of the whole, sound over reference, in dB; at, frame: the 10 ms
# frame whose level differs most (of those within 60 dB of the reference's
# loudest), when it starts in seconds, and by how many dB.
sub compare ($reference, $sound) {
    die "lengths differ\n" if @$reference != @$sound;
    my ($energy, $error, $total) = (0, 0, 0);
    my (@ref, @snd);
    for my $i (0 .. $#$reference) {
        my ($r, $s) = ($reference->[$i], $sound->[$i]);
        $energy += $r * $r;
        $total  += $s * $s;
        $error  += ($r - $s) ** 2;
        $ref[ $i / $FRAME ] += $r * $r;
        $snd[ $i / $FRAME ] += $s * $s;
    }
    my $db = sub ($a, $b) { 10 * log(($a + 1) / ($b + 1)) / log(10) };    # 1: a sample's least step, squared
    my $loudest = (sort { $b <=> $a } @ref)[0];
    my ($at, $frame) = (0, 0);
    for my $f (0 .. $#ref) {
        next if $ref[$f] < $loudest * 1e-6 && $snd[$f] < $loudest * 1e-6;
        my $d = $db->($snd[$f], $ref[$f]);
        ($at, $frame) = ($f * $FRAME / $RATE, $d) if abs $d > abs $frame;
    }
    return { snr => $error ? $db->($energy, $error) : 'inf', level => $db->($total, $energy), at => $at, frame => $frame,
        peak => (sort { $b <=> $a } map { abs } @$reference)[0] };
}

1;
