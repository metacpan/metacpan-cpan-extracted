package Peta::Synth::Output;
# ABSTRACT: sound to WAV, FLAC, MP3, Ogg Vorbis and Opus files

# Where rendered sound goes: a writer takes it in pieces (left and right as
# arrays of floats in -1 .. 1) and is closed at the end.
#
#   wav    written here: 16 bits (dithered), 24 bits, or 32-bit floats
#   flac   encoded here (Peta::Synth::Output::FLAC): 16 or 24 bits
#   mp3    encoded here (Peta::MP3::Encode): constant or variable bitrate
#   ogg    encoded here (Peta::Vorbis::Encode): Ogg Vorbis, by quality
#   opus   encoded by ffmpeg fed WAV through a pipe, until there is an
#          encoder here
#
# Every writer has write(\@left, \@right) and close. The class methods open
# one for a file by its extension.

use v5.36;
use File::Spec;

our $VERSION = '0.2610180';

# The format of each file name extension, and the class that writes it.
my %FORMAT_OF = (wav => 'wav', flac => 'flac', mp3 => 'mp3', ogg => 'ogg', oga => 'ogg', opus => 'opus');
my %WRITER    = (
    wav  => 'Peta::Synth::Output::WAV',
    flac => 'Peta::Synth::Output::FLAC',
    mp3  => 'Peta::Synth::Output::MP3',
    ogg  => 'Peta::Synth::Output::Vorbis',
    opus => 'Peta::Synth::Output::Pipe',
);

# The format a file's name says.
sub format_of ($file) {
    my ($ext) = $file =~ /\.(\w+)\z/;
    my $format = $FORMAT_OF{ lc($ext // '') };
    return $format if $format;

    my $have = join ' ', sort keys %FORMAT_OF;
    die "'$file': cannot tell the format from the name (have: $have)\n";
}

# Where a program is on the PATH, if it is.
sub which ($program) {
    for my $dir (File::Spec->path) {
        my $path = File::Spec->catfile($dir, $program);
        return $path if -f $path && -x _;
    }
    return;
}

# The formats this machine can write, and whether each is written here.
sub formats () {
    my $ffmpeg = which('ffmpeg');
    my %have = (wav => 'native', flac => 'native', mp3 => 'native', ogg => 'native');
    $have{opus} = 'external' if $ffmpeg;
    return \%have;
}

# open($file, rate => 48000, bits => 16, quality => ...): a writer for the
# format the file's name says.
sub open ($class, $file, %opt) {
    my $format = format_of($file);
    require Peta::Synth::Output::FLAC if $format eq 'flac';
    return $WRITER{$format}->new($file, format => $format, %opt);
}

# Convenience: a whole sound at once.
sub write_file ($class, $file, $left, $right, %opt) {
    my $out = $class->open($file, %opt);
    my $step = 65536;
    for (my $at = 0; $at < @$left; $at += $step) {
        my $end = $at + $step - 1;
        $end = $#$left if $end > $#$left;
        $out->write([ @$left[ $at .. $end ] ], [ @$right[ $at .. $end ] ]);
    }
    return $out->close;
}

# The two channels' samples, interleaved: left, right, left, ...
sub interleave ($left, $right) {
    my $n     = @$left;
    my @inter = (0) x (2 * $n);
    for my $i (0 .. $n - 1) {
        $inter[2 * $i]     = $left->[$i];
        $inter[2 * $i + 1] = $right->[$i];
    }
    return \@inter;
}

# Integer samples from floats, interleaved: clipped, and with triangular
# dither of one step (from a fixed stream: the same file every time) when
# there are 16 bits. The state of the dither is kept in $state.
sub to_integers ($left, $right, $bits, $state) {
    my $n = scalar @$left;
    my @out = (0) x (2 * $n);
    my $scale = $bits == 16 ? 32767.0 : 8388607.0;
    my $top   = $scale;
    my $low   = -$scale - 1.0;
    my $dither = $bits == 16 ? 1.0 : 0.0;
    my $s = $$state;
    for my $i (0 .. $n - 1) {
        $s = ($s * 1103515245 + 12345) % 2147483648;
        my $r = $s / 2147483648.0;
        $s = ($s * 1103515245 + 12345) % 2147483648;
        $r -= $s / 2147483648.0;
        my $v = $left->[$i] * $scale + $dither * $r;
        $v = $top if $v > $top;
        $v = $low if $v < $low;
        $out[2 * $i] = int($v + ($v < 0.0 ? -0.5 : 0.5));

        $v = $right->[$i] * $scale + $dither * $r * -1.0;
        $v = $top if $v > $top;
        $v = $low if $v < $low;
        $out[2 * $i + 1] = int($v + ($v < 0.0 ? -0.5 : 0.5));
    }
    $$state = $s;
    return \@out;
}

package Peta::Synth::Output::WAV;

# RIFF WAVE: the header is written with the sizes unknown and set at close,
# or, when the output cannot seek (a pipe), with the largest sizes, which
# readers take as "until the end".

use v5.36;

# new($file, rate => 48000, bits => 16, fh => ...): with fh, onto that handle.
sub new ($class, $file, %opt) {
    my $bits = $opt{bits} // 16;
    die "WAV is written with 16, 24 or 32 (float) bits, not $bits\n" if $bits !~ /\A(?:16|24|32)\z/;

    my $fh = $opt{fh};
    if (!$fh) {
        open $fh, '>:raw', $file or die "cannot write '$file': $!\n";
    }
    binmode $fh;

    my $self = bless {
        file   => $file,
        fh     => $fh,
        rate   => $opt{rate} // 48000,
        bits   => $bits,
        frames => 0,
        dither => 1,    # Peta::Synth::Output::to_integers' state
    }, $class;
    print {$fh} $self->_header(0xffffffff - 36);
    return $self;
}

# The header, for $bytes of samples.
sub _header ($self, $bytes) {
    my $bits  = $self->{bits};
    my $block = 2 * $bits / 8;    # bytes per frame
    my $type  = $bits == 32 ? 3 : 1;    # IEEE float, or PCM

    return join '',
        pack('a4 V a4', 'RIFF', 36 + $bytes, 'WAVE'),
        pack('a4 V v v V V v v', 'fmt ', 16, $type, 2, $self->{rate}, $self->{rate} * $block, $block, $bits),
        pack('a4 V', 'data', $bytes);
}

sub write ($self, $left, $right) {
    my $bits = $self->{bits};
    my $data;
    if ($bits == 32) {
        $data = pack 'f<*', @{ Peta::Synth::Output::interleave($left, $right) };
    }
    else {
        my $samples = Peta::Synth::Output::to_integers($left, $right, $bits, \$self->{dither});
        $data = $bits == 16 ? pack('s<*', @$samples) : join '', map { substr pack('l<', $_), 0, 3 } @$samples;
    }
    print { $self->{fh} } $data;
    $self->{frames} += @$left;
    return $self;
}

sub close ($self) {
    my $fh = $self->{fh};
    my $bytes = $self->{frames} * 2 * $self->{bits} / 8;
    if (seek $fh, 0, 0) {
        print {$fh} $self->_header($bytes);
    }
    close $fh or die "cannot write '$self->{file}': $!\n";
    return $self->{file};
}

package Peta::Synth::Output::Pipe;

# A format encoded by an external program, fed WAV through a pipe.

use v5.36;

sub _command ($format, $file, $quality) {
    my $ffmpeg = Peta::Synth::Output::which('ffmpeg');
    my @ff = ($ffmpeg, qw(-hide_banner -loglevel error -y -f wav -i pipe:0));
    if ($format eq 'opus') {
        return [ @ff, qw(-codec:a libopus -b:a), ($quality // 160) . 'k', $file ] if $ffmpeg;
    }
    die "cannot write $format here: it is encoded by ffmpeg, and it is not on the PATH\n";
}

sub new ($class, $file, %opt) {
    my $command = _command($opt{format}, $file, $opt{quality});
    open my $fh, '|-', @$command or die "cannot run $command->[0]: $!\n";
    binmode $fh;
    my $wav = Peta::Synth::Output::WAV->new(undef, %opt, bits => 16, fh => $fh);
    return bless { file => $file, wav => $wav, fh => $fh, program => $command->[0] }, $class;
}

sub write ($self, $left, $right) {
    $self->{wav}->write($left, $right);
    return $self;
}

sub close ($self) {
    close $self->{fh} or die "$self->{program} could not write '$self->{file}' (exit " . ($? >> 8) . ")\n";
    return $self->{file};
}

package Peta::Synth::Output::MP3;

# Layer III (MPEG-1, or MPEG-2 at 16-24 kHz), encoded here: the quality in
# kbit/s (a constant bitrate), or V0 .. V9 (a variable one, as LAME's -V).

use v5.36;

sub new ($class, $file, %opt) {
    require Peta::MP3::Encode;
    my $rate = $opt{rate} // 48000;
    die "MP3 is written at 32000, 44100 or 48000 Hz (MPEG-1), 16000, 22050 or 24000 Hz (MPEG-2), not $rate\n"
        if $rate !~ /\A(?:32000|44100|48000|16000|22050|24000)\z/;
    my $quality = $opt{quality};
    my %bitrate;
    if    (!defined $quality)              { %bitrate = () }
    elsif ($quality =~ /\A[Vv]([0-9])\z/)   { %bitrate = (vbr => $1) }
    else                                   { %bitrate = (bitrate => $quality) }

    my $encoder = Peta::MP3::Encode->new(rate => $rate, channels => 2, %bitrate, ffmpeg_gapless => $opt{ffmpeg_gapless});
    open my $fh, '>:raw', $file or die "cannot write '$file': $!\n";
    print {$fh} $encoder->info_frame;    # its place; written again at the end
    return bless { file => $file, fh => $fh, encoder => $encoder }, $class;
}

sub write ($self, $left, $right) {
    print { $self->{fh} } $self->{encoder}->encode($left, $right);
    return $self;
}

sub close ($self) {
    my $fh = $self->{fh};
    print {$fh} $self->{encoder}->finish;
    print {$fh} $self->{encoder}->info_frame if seek $fh, 0, 0;
    close $fh or die "cannot write '$self->{file}': $!\n";
    return $self->{file};
}

package Peta::Synth::Output::Vorbis;

# Ogg Vorbis, encoded here: variable bitrate, the quality 0 to 10.

use v5.36;

sub new ($class, $file, %opt) {
    require Peta::Vorbis::Encode;
    my $encoder = Peta::Vorbis::Encode->new(rate => $opt{rate} // 48000, channels => 2, quality => $opt{quality} // 6);
    open my $fh, '>:raw', $file or die "cannot write '$file': $!\n";
    return bless { file => $file, fh => $fh, encoder => $encoder }, $class;
}

sub write ($self, $left, $right) {
    print { $self->{fh} } $self->{encoder}->encode($left, $right);
    return $self;
}

sub close ($self) {
    my $fh = $self->{fh};
    print {$fh} $self->{encoder}->finish;
    close $fh or die "cannot write '$self->{file}': $!\n";
    return $self->{file};
}

package Peta::Synth::Output;

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Synth::Output - sound to WAV, FLAC, MP3, Ogg Vorbis and Opus files

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    use Peta::Synth::Output;

    my $out = Peta::Synth::Output->open('song.flac', rate => 48000, bits => 24);
    while (...) {
        $out->write(\@left, \@right);       # floats in -1 .. 1
    }
    $out->close;

    my $have = Peta::Synth::Output::formats();   # { wav => 'native', flac => 'native', mp3 => 'external', ... }

=head1 DESCRIPTION

Writers that take sound in pieces. WAV, FLAC, MP3 and Ogg Vorbis are
written by this distribution and need nothing else; Opus is, for now,
encoded by C<ffmpeg> fed through a pipe.
Samples outside -1 .. 1 are clipped; 16-bit output is dithered.

=head1 METHODS

=head2 open

C<< open($file, rate => 48000, bits => 16, quality => ..., ffmpeg_gapless => 0) >>: a writer for
the format the extension names (C<.wav>, C<.flac>, C<.mp3>, C<.ogg>,
C<.oga>, C<.opus>). C<bits> is 16, 24 or 32 (float) for WAV, 16 or 24 for
FLAC. C<quality> is the compression level for FLAC (0 .. 8, default 5), the
bitrate in kbit/s for MP3 (default 192; 32 to
320; at 16 to 24 kHz default 96, 8 to 160) or C<V0> to C<V9> for a variable one (as LAME's C<-V>), the Vorbis quality (0 .. 10, default 6), kbit/s for Opus (default
160). MP3 is written at 32, 44.1 or 48 kHz (MPEG-1) or 16, 22.05 or 24 kHz
(MPEG-2). C<ffmpeg_gapless>: an MP3's Info tag
names the encoder C<LavfPeta>, so that FFmpeg plays it gapless; see
L<Peta::MP3::Encode/"THE ENCODER'S NAME">.

=head2 write, close

C<write(\@left, \@right)> appends; C<close> finishes the file and returns
its name.

=head2 write_file

C<< write_file($file, \@left, \@right, %opt) >>: a whole sound at once.

=head1 FUNCTIONS

=head2 formats

The formats this machine can write: C<native> or C<external>.

=head2 format_of

The format a file name asks for.

=head2 interleave

C<interleave(\@left, \@right)>: the samples of both channels in one array,
left, right, left, ...

=head2 to_integers

C<to_integers(\@left, \@right, $bits, \$state)>: interleaved integer
samples of 16 bits (dithered) or 24 bits.

=head2 which

The path of a program on the PATH, or nothing.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
