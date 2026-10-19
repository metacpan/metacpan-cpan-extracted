package Peta::Synth;
# ABSTRACT: a software synthesizer in Perl

# A software synthesizer in Perl: MIDI files to sound, every instrument
# synthesized (no samples), on whatever this perl and this machine have:
# plain Perl, pperl's JIT, PDL, a graphics card through pperl's WebGPU.
#
# This module is the front: rendering a file offline, with the voices
# shared among processes when asked; playing it as it renders; playing
# MIDI as it comes in. The parts:
#
#   Peta::Synth::MIDI      Standard MIDI Files, single messages (::Stream: a device's bytes)
#   Peta::Synth::Input     MIDI as it is played: the ALSA sequencer, raw devices
#   Peta::Synth::Synth     the running synthesizer: channels, MIDI's messages, voices, the mix
#   Peta::Synth::Patch     the fields of a patch, the General MIDI instruments, the drum kit
#   Peta::Synth::Voice     the voice model: partials, string, FM, noise, filter, modulation
#   Peta::Synth::Engine    the engines that render voices
#   Peta::Synth::Reverb    the reverb;  Peta::Synth::EQ  the equalizers
#   Peta::Synth::Output    WAV, FLAC, MP3 and Ogg Vorbis written here, Opus through ffmpeg;
#                          the sound server (Output::PipeWire, Output::Pulse)
#
# What each does is told in doc/: midi.md, synthesis.md, rendering.md, backends.md.

use v5.36;
use File::Temp qw(tempfile);
use List::Util qw(max sum0);
use POSIX ();
use Time::HiRes ();
use Peta::Synth::MIDI;
use Peta::Synth::Synth;
use Peta::Synth::Engine;
use Peta::Synth::Output;

our $VERSION = '0.2610180';

use constant QUANTUM => 1024;

my %DEFAULT = (
    rate           => 48000,
    partials       => 48,
    fidelity       => 'high',
    engine         => 'auto',
    workers        => 1,
    bits           => 16,
    normalize      => -1.0,
    tail           => 30,
    quality        => undef,
    ffmpeg_gapless => 0,
    waves          => undef,
);

# Renders a MIDI file into a sound file.
#
#   rate        sample rate (48000)
#   partials    the most partials a voice has (48): the main measure of quality and cost
#   fidelity    low, mid or high (high): what may be left out that is hardly heard
#               (Peta::Synth::Synth: voices end sooner as they fade, fewer at once)
#   engine      perl, pdl, gpu or auto
#   workers     processes the voices are shared among (1)
#   bits        16, 24 or 32 (float, WAV only)
#   normalize   the peak in dBFS the result is scaled to (-1); undef: as rendered
#   tail        the most seconds rendered after the last event, for the release and reverb (30)
#   length      only the file's first seconds
#   bank        changes to the patches, as Peta::Synth::Synth's edits() gives them
#   waves       harmonic partials read from wave sequences (Peta::Synth::Wavetable): 1, 0, or
#               undef: as the engine fares better (Peta::Synth::Synth)
#   progress    a sub called with (seconds rendered, seconds in all)
#
# Returns a hash of what was done: seconds of sound, seconds it took, notes,
# peak voices, the engine.
sub render_file ($class, $in, $out, %opt) {
    my %o = (%DEFAULT, %opt);
    my ($timeline, $length) = _timeline($in, $o{length});
    my $started = Time::HiRes::time();

    # Measured once, here, not by every worker.
    $o{engine} = Peta::Synth::Engine::choose(rate => $o{rate}, partials => $o{partials}) if $o{engine} eq 'auto';

    my $workers = $o{workers} > 1 ? $o{workers} : 1;
    my @parts   = $workers == 1
        ? _render_part($timeline, $length, \%o, undef, $o{progress}, _temp_file('part'))
        : _render_parts($timeline, $length, \%o, $workers);

    my $result = _mix_down(\@parts, $out, \%o);
    unlink $_->{file} for @parts;

    $result->{took}        = Time::HiRes::time() - $started;
    $result->{notes}       = sum0 map { $_->{notes} } @parts;
    $result->{peak_voices} = sum0 map { $_->{peak_voices} } @parts;
    $result->{engine}      = $parts[0]{engine};
    $result->{workers}     = $workers;
    return $result;
}

# What rendering a MIDI file will cost, before it is rendered: its
# Peta::Synth::Profile. rate, partials, bank, length, tail, waves as for render_file.
sub profile_file ($class, $in, %opt) {
    my %o = (%DEFAULT, %opt);
    my ($timeline, $length) = _timeline($in, $o{length});
    require Peta::Synth::Profile;
    return Peta::Synth::Profile->new(
        timeline => $timeline,
        length   => $length,
        tail     => $o{tail},
        rate     => $o{rate},
        partials => $o{partials},
        bank     => $o{bank},
        waves    => $o{waves},
    );
}

# A MIDI file's events, as far as $length seconds if that is given (what
# still sounds there is let go), and the time of the last.
sub _timeline ($in, $length) {
    my $midi     = ref $in ? $in : Peta::Synth::MIDI->read($in);
    my $timeline = $midi->timeline;

    if (defined $length) {
        my @all_sound_off = map { { time => $length, type => 'controller', channel => $_, number => 123, value => 0 } } 0 .. 15;
        $timeline = [ (grep { $_->{time} < $length } @$timeline), @all_sound_off ];
    }
    return ($timeline, @$timeline ? $timeline->[-1]{time} : 0);
}

# Plays a MIDI file on the sound server as it renders.
#
#   rate, partials, engine, bank, length, tail   as for render_file
#   fidelity   as for render_file, but mid by default
#   latency    seconds the server holds ahead of what it plays (0.15)
#   output     pipewire (pperl: libpipewire through Peta::FFI), pulse (the
#              PulseAudio protocol, which PipeWire serves too), or auto (pipewire
#              where it can be, pulse otherwise)
#   auto       new notes get fewer partials when the machine cannot keep up (1)
#   prepare    the wave sequences the file needs made before it plays (1), so
#              that no note waits for its; prepared, a sub called with (the
#              sequences, the seconds it took) once they are
#   stop       a sub: when it says so, playing stops at once
#   progress   a sub called with (seconds played, seconds in all, the synthesizer)
#
# The sound is not normalized (its peak is not known before it is played):
# the synthesizer's limiter keeps it from clipping.
sub play_file ($class, $in, %opt) {
    my %o = (%DEFAULT, fidelity => 'mid', latency => 0.15, auto => 1, output => 'auto', prepare => 1, %opt);
    my ($timeline, $length) = _timeline($in, $o{length});
    my $engine = Peta::Synth::Engine::create($o{engine}, rate => $o{rate}, partials => $o{partials});
    my $waves  = $o{waves} // ($engine->can('reads_waves') ? $engine->reads_waves : 1);
    $waves = _prepared_waves($timeline, $length, \%o) if $waves && $o{prepare};

    my $synth = Peta::Synth::Synth->new(rate => $o{rate}, partials => $o{partials}, fidelity => $o{fidelity}, engine => $engine, waves => $waves);
    $synth->apply_edits($o{bank}) if $o{bank};
    $synth->schedule($timeline);
    my $title = ref $in ? 'Peta::Synth' : $in =~ s{.*/}{}r;
    my $out   = player($o{output}, rate => $o{rate}, latency => $o{latency}, title => $title);

    my $limit   = int(($length + $o{tail}) * $o{rate});
    my $stopped = 0;
    while ($synth->busy && $synth->now < $limit) {
        if ($o{stop} && $o{stop}->()) {
            $stopped = 1;
            last;
        }
        _play_quantum($synth, $out, QUANTUM, \%o);
        $o{progress}->($synth->now / $o{rate}, $length, $synth) if $o{progress};
    }

    if ($stopped) {
        $out->stop;
    }
    else {
        $out->close;
    }
    my $stats = $synth->stats;
    return {
        seconds     => $synth->now / $o{rate},
        notes       => $stats->{notes},
        peak_voices => $stats->{peak_voices},
        engine      => $engine->name,
        stopped     => $stopped,
        partials    => $synth->{partials},
        output      => ref($out) =~ s/.*:://r,
    };
}

# The wave sequences a file's notes read, made before it plays: every note
# foreseen (by a Peta::Synth::Profile) makes its own.
sub _prepared_waves ($timeline, $length, $o) {
    require Peta::Synth::Profile;
    my $started = Time::HiRes::time();
    my $waves   = Peta::Synth::Wavetable->new;
    Peta::Synth::Profile->new(
        timeline => $timeline,
        length   => $length,
        tail     => $o->{tail},
        rate     => $o->{rate},
        partials => $o->{partials},
        bank     => $o->{bank},
        waves    => $waves,
    );
    $o->{prepared}->($waves->stats, Time::HiRes::time() - $started) if $o->{prepared};
    return $waves;
}

# Plays MIDI as it comes in (Peta::Synth::Input): from a keyboard, a
# sequencer, a pipe, until stop says so.
#
#   rate, partials, engine, bank   as for render_file
#   fidelity   as for render_file, but mid by default
#   in         what to read: all (every source, and those plugged in later),
#              none (a port for others to connect), sources by address or
#              name, or a path (a raw MIDI device, a pipe); see Peta::Synth::Input
#   latency    seconds the server holds ahead (0.03)
#   quantum    samples rendered at a time (256): with the latency, how late a
#              key is heard
#   output     as for play_file, or an object that writes (write, stop)
#   auto, stop as for play_file
#   progress   a sub called with (the synthesizer, the input) after each quantum
sub play_live ($class, %opt) {
    my %o = (%DEFAULT, fidelity => 'mid', in => 'all', latency => 0.03, quantum => 256, auto => 1, output => 'auto', %opt);
    die "a quantum is a multiple of 64 samples\n" if $o{quantum} % 64 || $o{quantum} < 64;

    require Peta::Synth::Input;
    my $in     = Peta::Synth::Input->open($o{in});
    my $engine = Peta::Synth::Engine::create($o{engine}, rate => $o{rate}, partials => $o{partials});
    my $synth  = Peta::Synth::Synth->new(rate => $o{rate}, partials => $o{partials}, fidelity => $o{fidelity}, engine => $engine, waves => $o{waves});
    $synth->apply_edits($o{bank}) if $o{bank};
    my $out = ref $o{output}
        ? $o{output}
        : player($o{output}, rate => $o{rate}, latency => $o{latency}, title => 'Peta::Synth');

    my $notes = 0;
    until ($o{stop} && $o{stop}->()) {
        for my $event ($in->events) {
            $notes++ if $event->{type} eq 'note_on';
            $synth->play($event);
        }
        _play_quantum($synth, $out, $o{quantum}, \%o);
        $o{progress}->($synth, $in) if $o{progress};
    }

    $out->stop;
    return {
        seconds  => $synth->now / $o{rate},
        notes    => $notes,
        engine   => $engine->name,
        partials => $synth->{partials},
        output   => ref($out) =~ s/.*:://r,
        input    => $in->address,
    };
}

# One quantum rendered and written; the time it took told to the
# synthesizer, which (with auto) gives new notes fewer partials if it falls behind.
sub _play_quantum ($synth, $out, $quantum, $o) {
    my $started = Time::HiRes::time();
    my ($left, $right) = $synth->render_arrays($quantum);
    $synth->account(Time::HiRes::time() - $started, $quantum);
    $synth->adapt($o->{partials}) if $o->{auto};
    $out->write($left, $right);
    return;
}

# A writer that plays: 'pipewire', 'pulse', or 'auto' (PipeWire where this
# perl can call libpipewire, the PulseAudio protocol otherwise).
sub player ($name, %opt) {
    if ($name eq 'pipewire' || $name eq 'auto') {
        require Peta::Synth::Output::PipeWire;
        my $out = Peta::Synth::Output::PipeWire::available() && eval { Peta::Synth::Output::PipeWire->new(%opt) };
        return $out if $out;
        die $@ || "PipeWire cannot be played to from here\n" if $name eq 'pipewire';
    }
    die "no such output: $name (pipewire, pulse, auto)\n" if $name ne 'pulse' && $name ne 'auto';

    require Peta::Synth::Output::Pulse;
    return Peta::Synth::Output::Pulse->new(%opt);
}

# The voices shared among $workers processes, each rendering its part into a
# file of its own; what each did is passed back in a file beside it.
sub _render_parts ($timeline, $length, $o, $workers) {
    my @children;
    for my $w (0 .. $workers - 1) {
        my $file     = _temp_file('part');
        my $progress = $w == 0 ? $o->{progress} : undef;

        my $pid = fork // die "cannot fork: $!\n";
        if (!$pid) {
            my $done = eval {
                _write_stats("$file.stats", _render_part($timeline, $length, $o, [ $w, $workers ], $progress, $file));
                1;
            };
            warn $@ unless $done;
            POSIX::_exit($done ? 0 : 1);
        }
        push @children, [ $pid, $file ];
    }

    my @parts;
    for my $child (@children) {
        my ($pid, $file) = @$child;
        waitpid $pid, 0;
        die "a worker failed\n" if $?;
        push @parts, { file => $file, %{ _read_stats("$file.stats") } };
        unlink "$file.stats";
    }
    return @parts;
}

# A temporary file's name, the file made (and left to the caller to remove).
sub _temp_file ($what) {
    my ($fh, $file) = tempfile("peta-synth-$what-XXXXXX", TMPDIR => 1, UNLINK => 0);
    close $fh;
    return $file;
}

# One process's share: the notes whose number modulo the workers is its own
# (or all), rendered into $file as packed float frames (L R L R ...).
sub _render_part ($timeline, $length, $o, $share, $progress, $file) {
    my $engine = Peta::Synth::Engine::create($o->{engine});
    my $synth  = Peta::Synth::Synth->new(
        rate     => $o->{rate},
        partials => $o->{partials},
        fidelity => $o->{fidelity},
        engine   => $engine,
        limiter  => 0,
        gain     => 0.3,
        waves    => $o->{waves},
        $share ? (filter => sub ($id) { $id % $share->[1] == $share->[0] }) : (),
    );
    $synth->apply_edits($o->{bank}) if $o->{bank};
    $synth->schedule($timeline);

    open my $fh, '>:raw', $file or die "cannot write '$file': $!\n";
    my $rate  = $o->{rate};
    my $limit = int(($length + $o->{tail}) * $rate);
    my $peak  = 0;
    while ($synth->busy && $synth->now < $limit) {
        my ($left, $right) = $synth->render_arrays(QUANTUM);
        my @frames = (0.0) x (2 * QUANTUM);
        for my $i (0 .. QUANTUM - 1) {
            my ($l, $r) = ($left->[$i], $right->[$i]);
            $frames[ 2 * $i ]     = $l;
            $frames[ 2 * $i + 1 ] = $r;
            my $x = abs $l;
            $peak = $x if $x > $peak;
            $x = abs $r;
            $peak = $x if $x > $peak;
        }
        print {$fh} pack 'f*', @frames;
        $progress->($synth->now / $rate, $length) if $progress;
    }
    close $fh or die "cannot write '$file': $!\n";

    my $stats = $synth->stats;
    return {
        file        => $file,
        frames      => $synth->now,
        notes       => $stats->{notes},
        peak_voices => $stats->{peak_voices},
        engine      => $engine->name,
        # The peak as the file holds it: rounding to 32 bits keeps the order
        # of magnitudes, so the largest rounded is the largest, rounded.
        peak        => unpack('f', pack 'f', $peak),
    };
}

sub _write_stats ($file, $part) {
    open my $fh, '>', $file or die "cannot write '$file': $!\n";
    print {$fh} map { "$_\t$part->{$_}\n" } grep { $_ ne 'file' } sort keys %$part;
    close $fh;
    return;
}

sub _read_stats ($file) {
    open my $fh, '<', $file or die "a worker left no account of its work\n";
    my %stats = map { chomp; split /\t/, $_, 2 } <$fh>;
    return \%stats;
}

use constant CHUNK => 65536;    # frames read, summed and written at a time

# The parts summed, the sum scaled to the wanted peak and written.
sub _mix_down ($parts, $out, $o) {
    my $frames = max map { $_->{frames} } @$parts;

    # One part: its peak is known, and it is the sum.
    my ($sum_file, $peak) = @$parts == 1 ? ($parts->[0]{file}, $parts->[0]{peak}) : _sum($parts, $frames);
    my $scale = defined $o->{normalize} && $peak > 0 ? 10**($o->{normalize} / 20) / $peak : 1;

    my $writer = Peta::Synth::Output->open(
        $out,
        rate           => $o->{rate},
        bits           => $o->{bits},
        quality        => $o->{quality},
        ffmpeg_gapless => $o->{ffmpeg_gapless},
    );
    open my $in, '<:raw', $sum_file or die "cannot read '$sum_file': $!\n";
    for (my $at = 0; $at < $frames; $at += CHUNK) {
        my $count = $frames - $at < CHUNK ? $frames - $at : CHUNK;
        read($in, my $bytes, 8 * $count);
        my @inter = unpack 'f*', $bytes;
        my @left  = (0.0) x $count;
        my @right = (0.0) x $count;
        for my $i (0 .. $count - 1) {
            $left[$i]  = $inter[ 2 * $i ] * $scale;
            $right[$i] = $inter[ 2 * $i + 1 ] * $scale;
        }
        $writer->write(\@left, \@right);
    }
    close $in;
    unlink $sum_file if @$parts > 1;
    $writer->close;

    return { seconds => $frames / $o->{rate}, peak => $peak, scale => $scale, file => $out };
}

# Several parts added up, chunk by chunk, into a temporary file: its name,
# and the peak found on the way.
sub _sum ($parts, $frames) {
    my @in = map { open my $fh, '<:raw', $_->{file} or die "cannot read '$_->{file}': $!\n"; $fh } @$parts;
    my ($out, $file) = tempfile('peta-synth-sum-XXXXXX', TMPDIR => 1, UNLINK => 1);
    binmode $out;

    my $peak = 0;
    for (my $at = 0; $at < $frames; $at += CHUNK) {
        my $count = $frames - $at < CHUNK ? $frames - $at : CHUNK;
        my @sum   = (0.0) x (2 * $count);
        for my $fh (@in) {
            read($fh, my $bytes, 8 * $count);
            my @part = unpack 'f*', $bytes;
            for my $i (0 .. $#part) {
                $sum[$i] += $part[$i];
            }
        }
        for my $i (0 .. $#sum) {
            my $a = abs $sum[$i];
            $peak = $a if $a > $peak;
        }
        print {$out} pack 'f*', @sum;
    }
    close $_ for @in;
    close $out;
    return ($file, $peak);
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Synth - a software synthesizer in Perl

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    use Peta::Synth;

    my $done = Peta::Synth->render_file('song.mid', 'song.flac',
        rate => 48000, partials => 64, engine => 'auto', workers => 2);
    printf "%.1f s of sound in %.1f s\n", $done->{seconds}, $done->{took};

=head1 DESCRIPTION

Plays MIDI with instruments that are synthesized, not sampled: each voice
sine partials, a plucked or struck string, FM operators and bands of noise
under envelopes, a filter that moves and routes of modulation (see
L<Peta::Synth::Voice>), the 128 General MIDI programs and the drum kit
described as such (L<Peta::Synth::Patch>), a reverb and equalizers. It
runs on perl5 and on pperl, where the JIT compiles its loops; PDL and a
graphics card (pperl's WebGPU) are used where they are there.

The parts are listed at the top of the source; what they can do is told
in the distribution's F<doc/> (F<midi.md>, F<synthesis.md>,
F<rendering.md>, F<backends.md>). For a synthesizer of one's own to play
into, see L<Peta::Synth::Synth>.

=head1 METHODS

=head2 play_file

    Peta::Synth->play_file('song.mid', latency => 0.15, stop => sub { $stop });

Plays a MIDI file on the sound server (PulseAudio, or PipeWire through its
pipewire-pulse) as it renders: L<Peta::Synth::Output::Pulse>. Options as
for C<render_file> (C<rate>, C<partials>, C<engine>, C<bank>, C<length>,
C<tail>), and C<output> (C<pipewire>: libpipewire through pperl's
Peta::FFI, L<Peta::Synth::Output::PipeWire>; C<pulse>: the PulseAudio
protocol, which PipeWire also serves, L<Peta::Synth::Output::Pulse>;
C<auto>: PipeWire where it can be), C<latency> (seconds the server holds ahead, 0.15), C<auto>
(fewer partials for new notes when the machine cannot keep up, 1), C<stop>
(a sub that says when to stop at once), C<progress> (called with the
seconds played, the seconds in all and the synthesizer). The sound is not
normalized; the limiter keeps it from clipping. Returns C<seconds>,
C<notes>, C<peak_voices>, C<engine>, C<partials> (at the end), C<output>
and C<stopped>.

=head2 play_live

    Peta::Synth->play_live(in => 'all', latency => 0.03, stop => sub { $stop });

Plays MIDI as it comes in (L<Peta::Synth::Input>) on the sound server,
until C<stop> says so. C<in>: C<all> (every source of the ALSA sequencer,
and those plugged in later), C<none> (a port for others to connect),
sources by address or name joined by commas, or the path of a raw MIDI
device or pipe. C<quantum>: the samples rendered at a time, a multiple of
64 (256); each quantum's MIDI is applied before it is rendered. C<rate>,
C<partials>, C<engine>, C<bank>, C<latency> (0.03), C<auto> as for
C<play_file>; C<output> as there, or an object that writes (C<write>,
C<stop>); C<progress> is called with the synthesizer and the input after
each quantum. Returns C<seconds>, C<notes>, C<engine>, C<partials>,
C<output> and C<input> (the port's address).

=head2 profile_file

C<< Peta::Synth->profile_file($in, rate => ..., partials => ..., bank => ..., length => ..., tail => ...) >>:
what rendering a MIDI file will cost, before it is rendered: its
L<Peta::Synth::Profile>.

=head2 player

C<< Peta::Synth::player($output, rate => ..., latency => ..., title => ...) >>:
the writer C<play_file> plays through.

=head2 render_file

C<< render_file($midi, $out, %opt) >>: renders a MIDI file (a name or a
L<Peta::Synth::MIDI>) into C<$out>, in the format its extension names (see
L<Peta::Synth::Output>). Options:

=over

=item rate

The sample rate (48000).

=item partials

The most partials a voice has (48): the main measure of quality, and of
the time a render takes.

=item fidelity

C<low>, C<mid> or C<high> (C<high>): what may be left out that is hardly
heard, as L<Peta::Synth::Synth> has it (voices end sooner as they fade,
fewer sound at once). C<high> renders sample for sample as ever;
C<play_file> and C<play_live> take C<mid> by default.

=item engine

C<perl>, C<pdl>, C<gpu> or C<auto> (L<Peta::Synth::Engine>).

=item workers

The number of processes the notes are shared among (1). The reverb is
linear, so each process runs its own and the parts are summed.

=item bits

16 (dithered), 24, or 32 (float, WAV only).

=item normalize

The peak, in dBFS, the result is scaled to (-1); C<undef> leaves it as
rendered.

=item tail

The most seconds rendered after the last event (30); rendering stops as
soon as everything is silent.

=item bank

Changes to the instruments, as L<Peta::Synth::Synth/edits> gives them (the web
page saves them as a JSON file).

=item length

Only the first seconds of the file; notes still held there are let go.

=item quality

The encoder's quality: the compression level for FLAC (0-8, 5); for MP3
kbit/s (192, at 16-24 kHz 96) or C<V0> .. C<V9> (a variable bitrate, as
LAME's C<-V>); the Vorbis quality for Ogg (0-10, 6); kbit/s for Opus (160).

=item ffmpeg_gapless

An MP3's Info tag names the encoder C<LavfPeta>, so that FFmpeg plays it
gapless (L<Peta::MP3::Encode/"THE ENCODER'S NAME">).

=item progress

A sub called with the seconds rendered and the length of the file.

=back

Returns a hash: C<seconds> of sound, C<took> (seconds), C<notes>,
C<peak_voices>, C<engine>, C<workers>, C<peak>, C<file>.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
