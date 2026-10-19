package Peta::Synth::Wavetable;
# ABSTRACT: partials compiled into wave sequences, made once and kept

# Partials compiled into wave sequences: a voice whose partials are
# harmonics (each copy of its unison: harmonics of the copy's own
# fundamental) sounds the same read from tables of one period each, one
# table for every moment where its spectrum has moved by some 3 dB (each
# partial's decay and fade-in), crossfaded from one to the next. Reading
# two tables costs the same whatever the number of partials; the partials,
# turned one by one, cost each its own.
#
# A sequence is made once for what its partials are (their harmonics,
# amplitudes, decays and fade-ins: whatever the patch, key, velocity,
# channel and budget made them) and kept: every voice with the same
# partials reads it, each from its own place in the period (so that two
# alike are not one, louder). Its partials' phases follow from what they
# are, so a sequence is the same whoever made it first.
#
# A sequence: { size (samples a period), times [ seconds since the voice
# began ], tables [ [ size + 1 samples (the last the first again) ] ] }.
# After the last time, the last table holds (the spectrum is still, or
# silent).

use v5.36;
use Digest::MD5 qw(md5);
use List::Util qw(max min);
use Peta::Synth::FFT;

our $VERSION = '0.2610180';

use constant TWO_PI => 6.283185307179586;
use constant {
    STEP      => 0.3466,   # ln(sqrt(2)): a partial moves 3 dB between tables at most
    SHORTEST  => 0.002,    # seconds between tables at the least, at most
    LONGEST   => 2,
    QUIET     => 1e-3,     # a partial under this much of the loudest one does not set the steps
    SILENT    => 1e-5,     # partials under this much of the start: the sequence ends
    TABLES    => 256,      # tables in a sequence at most
    PER_CYCLE => 32,       # samples a period of the highest harmonic, at the least
};

sub new ($class) {
    return bless {
        sequences => {},    # by the MD5 of their partials
        made      => 0,
        used      => 0,
        samples   => 0,
        seconds   => 0,
    }, $class;
}

# The sequence for partials [harmonic, amplitude, decay (1/s), fade-in (s)]:
# made, or found made.
sub sequence ($self, $partials) {
    my $key = md5(pack 'd*', map { @$_ } @$partials);
    $self->{used}++;
    return $self->{sequences}{$key} if $self->{sequences}{$key};

    require Time::HiRes;
    my $started  = Time::HiRes::time();
    my $sequence = _make($partials, $key);
    $self->{made}++;
    $self->{samples} += @{ $sequence->{tables} } * ($sequence->{size} + 1);
    $self->{seconds} += Time::HiRes::time() - $started;

    return $self->{sequences}{$key} = $sequence;
}

# How much was made and found: { sequences, made, used (made or found),
# samples (in all the tables), seconds (spent making them) }.
sub stats ($self) {
    return {
        sequences => scalar keys %{ $self->{sequences} },
        map { $_ => $self->{$_} } qw(made used samples seconds),
    };
}

# A voice's partials as copies of harmonics: [ [shift, [ [harmonic, amp,
# decay, attack] ... ]] ... ], one for each copy of the unison, $most at
# most (its frequency over the voice's fundamental, and the harmonics of
# that), or undef if they are not harmonics so (a stiff string's, a bell's).
sub harmonics ($ratio, $amp, $decay, $attack, $most = 1) {
    my @copies;     # [shift, partials]
    my %copy;       # shift => its copy
    for my $i (0 .. $#$ratio) {
        my $r = $ratio->[$i];
        # A copy's fundamental is its first partial's (the copies carry the strongest first).
        my $copy;
        for my $c (@copies) {
            my $h = $r / $c->[0];
            if (abs($h - int($h + 0.5)) < 1e-7 * $h && int($h + 0.5) >= 1) { $copy = $c; last }
        }
        if (!$copy) {
            # A new copy: the shift that makes this partial a whole harmonic of it.
            my $h = int($r + 0.5) || 1;
            my $shift = $r / $h;
            return undef if abs($shift - 1) > 0.03;     # not a detuned copy: not harmonic
            return undef if @copies >= $most;      # more copies than the unison has: a stiff string's partials
            $copy = [ $shift, [] ];
            push @copies, $copy;
        }
        push @{ $copy->[1] }, [ int($r / $copy->[0] + 0.5), $amp->[$i], $decay->[$i], $attack->[$i] ];
    }
    return \@copies;
}

# A partial's amplitude at a time.
sub _level ($p, $t) {
    my ($h, $a, $d, $att) = @$p;
    my $level = $a * exp(-$d * $t);
    return $att > 0 ? $level * (1 - exp(-$t / $att)) : $level;
}

# Whether a partial sets the steps between tables at time $t: one not much
# quieter than the loudest, or one still fading in.
sub _counts ($p, $level, $loudest, $t) {
    my $attack = $p->[3];
    return $level >= QUIET * $loudest || $attack > 0 && $t < 5 * $attack;
}

# How fast (1/s) a partial's level moves at a time, as a logarithm.
sub _rate ($p, $t) {
    my ($h, $a, $d, $att) = @$p;
    my $rate = $d;
    if ($att > 0) {
        my $e = exp(-$t / $att);
        $rate += $e / $att / (1 - $e) if $e < 1;
        $rate = 1e9 if $e >= 1;
    }
    return $rate;
}

sub _make ($partials, $key) {
    my $top = max(map { $_->[0] } @$partials);
    my $size = 64;
    $size *= 2 while $size < PER_CYCLE * $top && $size < 16384;
    # The phases, from what the partials are: the same sequence whoever makes it.
    my @phase = map { TWO_PI * unpack('N', md5($key . pack 'N', $_)) / 4294967296 } 0 .. $#$partials;
    my $start = max(map { $_->[1] } @$partials) || 1;
    my (@times, @tables);
    my $t = 0;
    while (1) {
        my @level = map { _level($_, $t) } @$partials;
        push @times, $t;
        push @tables, _table($size, $partials, \@level, \@phase);
        my $loudest = max(@level);
        last if @tables >= TABLES || $t > 0 && $loudest < SILENT * $start;
        # The next table where the fastest partial that counts has moved 3 dB.
        my @rates   = map { _counts($partials->[$_], $level[$_], $loudest, $t) ? _rate($partials->[$_], max($t, SHORTEST)) : 0 }
            0 .. $#$partials;
        my $fastest = max(0, @rates);
        last if $fastest < 1e-6;      # still: the last table holds
        $t += min(LONGEST, max(SHORTEST, STEP / $fastest));
    }
    return { size => $size, times => \@times, tables => \@tables };
}

# One period of the harmonics at their levels: by an inverse FFT, the
# period's samples the real parts.
sub _table ($size, $partials, $level, $phase) {
    my @re = ((0.0) x $size);
    my @im = ((0.0) x $size);
    for my $i (0 .. $#$partials) {
        my $h = $partials->[$i][0];
        next if $h >= $size / 2;
        # level sin(theta h + phase): the bin's conjugate, so that the forward transform inverts.
        $re[$h] += $level->[$i] * sin($phase->[$i]);
        $im[$h] += $level->[$i] * cos($phase->[$i]);
    }
    Peta::Synth::FFT::fft(\@re, \@im);
    push @re, $re[0];
    return \@re;
}

1;

__END__

=head1 NAME

Peta::Synth::Wavetable - partials compiled into wave sequences, made once and kept

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $waves = Peta::Synth::Wavetable->new;
    my $copies = Peta::Synth::Wavetable::harmonics(\@ratio, \@amp, \@decay, \@attack) or return;   # not harmonic
    my $sequence = $waves->sequence($copies->[0][1]);

=head1 DESCRIPTION

A voice whose partials are harmonics (each copy of its unison harmonics of
its own fundamental) sounds the same read from tables of one period each:
one for every moment where some partial has moved 3 dB (its decay, its
fade-in), crossfaded from one to the next, the last held. Two tables read
cost the same whatever the number of partials. A sequence is made once for
what its partials are and kept; every voice with those partials reads it,
from its own place in the period.

=head1 METHODS

=head2 new

A store of sequences.

=head2 sequence

C<sequence(\@partials)> (each C<[harmonic, amplitude, decay, fade-in]>):
C<< { size, times, tables } >>, made or found: C<size> samples a period
(at least 32 a period of the highest harmonic), C<times> (seconds since
the voice began), C<tables> (C<size> + 1 samples each, the last the first
again).

=head2 stats

C<< { sequences, made, used, samples, seconds } >>: what is kept, how many
were made and asked for, the samples in all the tables, the seconds spent
making them.

=head1 FUNCTIONS

=head2 harmonics

C<harmonics(\@ratio, \@amp, \@decay, \@attack, $most)> (a voice's partials, its unison's copies):
C<< [ [shift, [ [harmonic, amp, decay, attack], ... ]], ... ] >>, a copy
for each of the unison's (its fundamental over the voice's), or undef if
they are not harmonics so.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
