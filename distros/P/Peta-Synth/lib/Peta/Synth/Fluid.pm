package Peta::Synth::Fluid;
# ABSTRACT: FluidSynth as a reference: the same events, played from a SoundFont

# FluidSynth as a reference: the same MIDI events played by it from a
# General MIDI SoundFont (recorded instruments), to hear and measure this
# synthesizer's instruments against. Needs the program fluidsynth and a
# SoundFont; FluidR3, where the distributions put it, by default.

use v5.36;
use File::Temp qw(tempdir);
use Peta::Synth::Analysis;
use Peta::Synth::MIDI;

our $VERSION = '0.2610180';

our $SOUNDFONT = '/usr/share/soundfonts/FluidR3_GM.sf2';

# Whether FluidSynth can play here: '' if it can, why not if not.
sub unavailable ($soundfont = $SOUNDFONT) {
    return "no SoundFont at $soundfont" if !-e $soundfont;
    return 'fluidsynth is not installed' if system('fluidsynth --version >/dev/null 2>&1') != 0;
    return '';
}

# The events (as Peta::Synth::Synth's schedule takes them: time in seconds)
# played by FluidSynth: (\@left, \@right). Options: rate (48000),
# soundfont, effects (its reverb and chorus; off by default), length (in
# samples: cut or padded to it; FluidSynth stops at the last event).
sub render ($events, %opt) {
    my $rate = $opt{rate} // 48000;
    my $dir  = tempdir(CLEANUP => 1);

    # A crotchet of 480 ticks, 120 of them a minute: 960 ticks a second.
    my $tpq    = 480;
    my $second = 2 * $tpq;
    my @track  = ({ tick => 0, type => 'tempo', usec => 500000 });
    for my $event (sort { $a->{time} <=> $b->{time} } @$events) {
        my %e = %$event;
        $e{tick} = int(delete($e{time}) * $second + 0.5);
        push @track, \%e;
    }
    if ($opt{length}) {
        # An event at the end, which FluidSynth plays to.
        push @track, { tick => int($opt{length} / $rate * $second + 0.5), type => 'meta', meta => 0x01, data => 'end' };
    }
    Peta::Synth::MIDI->new(format => 0, division => $tpq, tracks => [ \@track ])->write("$dir/in.mid");

    render_file("$dir/in.mid", "$dir/out.wav", %opt);
    my $wav = Peta::Synth::Analysis::read_wav("$dir/out.wav");
    my ($left, $right) = @{ $wav->{channels} };
    if (my $length = $opt{length}) {
        for my $ch ($left, $right) {
            push @$ch, (0.0) x ($length - @$ch) if @$ch < $length;
            $#$ch = $length - 1;
        }
    }
    return ($left, $right);
}

# Where a program is compared, the lowest key its phrase or notes start
# from (two octaves above it they end): low instruments lower, high ones
# higher, the rest at 48.
#
#   36  the basses (32-39), cello, contrabass, tuba, baritone sax, bassoon,
#       bass and lead (87)
#   72  celesta, glockenspiel, music box, xylophone, piccolo, recorder,
#       whistle, ocarina, tinkle bell
#   55  violin, trumpet, muted trumpet, soprano sax, oboe, flute, pan flute,
#       fiddle, shanai
my %HOME = (
    (map { $_ => 36 } 32 .. 39, 42, 43, 58, 67, 70, 87),
    (map { $_ => 72 } 8, 9, 10, 13, 72, 74, 78, 79, 112),
    (map { $_ => 55 } 40, 56, 59, 64, 68, 73, 75, 110, 111),
);
sub home ($program) { return $HOME{$program} // 48 }

# A MIDI file played by FluidSynth into a WAV file (16 bits). Options as render's.
sub render_file ($midi, $wav, %opt) {
    my $rate = $opt{rate} // 48000;
    my $soundfont = $opt{soundfont} // $SOUNDFONT;
    my @effects = $opt{effects} ? () : ('-R', 0, '-C', 0);
    my $pid = fork // die "cannot fork: $!\n";
    if (!$pid) {
        open STDOUT, '>', '/dev/null';
        open STDERR, '>', '/dev/null';
        exec 'fluidsynth', '-ni', @effects, '-r', $rate, '-O', 's16', '-T', 'wav', '-F', $wav, $soundfont, $midi;
        exit 127;
    }
    waitpid $pid, 0;
    die "fluidsynth failed on $midi\n" if $? != 0 || !-s $wav;
    return $wav;
}

1;

__END__

=head1 NAME

Peta::Synth::Fluid - FluidSynth as a reference: the same events, played from a SoundFont

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    use Peta::Synth::Fluid;
    die $_ if $_ = Peta::Synth::Fluid::unavailable();
    my ($left, $right) = Peta::Synth::Fluid::render(\@events, rate => 48000, length => 48000 * 3);

=head1 DESCRIPTION

To hear and measure this synthesizer's instruments against recorded ones:
FluidSynth (the program C<fluidsynth>) plays the same MIDI events from a
General MIDI SoundFont, by default FluidR3 at
F</usr/share/soundfonts/FluidR3_GM.sf2>. Used by C<bin/peta-analyze>,
C<devbin/compare-fluid> and C<devbin/audit-fluid>; nothing else needs it.

=head1 FUNCTIONS

=head2 unavailable

C<unavailable($soundfont)>: the empty string if FluidSynth can play here,
else why not.

=head2 render

C<< render(\@events, rate => 48000, soundfont => ..., effects => 0, length => $samples) >>:
the events (times in seconds, as L<Peta::Synth::Synth/schedule> takes them)
as FluidSynth plays them, left and right. Its reverb and chorus are off
unless C<effects>; C<length> cuts or pads the sound to that many samples
(FluidSynth stops at the last event; the sound is rendered to there).

=head2 home

C<home($program)>: the key a program is compared from (48, the basses 36,
the high instruments 72, violin, trumpet, flute and the like 55); its
comparisons go two octaves up from it.

=head2 render_file

C<render_file($midi, $wav, %opt)>: a MIDI file into a WAV file.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
