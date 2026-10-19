package Peta::Synth::Reverb;
# ABSTRACT: a feedback delay network reverb

# A feedback delay network: eight delay lines of mutually prime lengths, fed
# back through a Hadamard matrix (which keeps the energy and mixes every
# line into every other), each line damped by a low-pass and attenuated so
# the tail falls 60 dB in the reverb time. Left and right are taken from
# different signs of the lines, which decorrelates them.
#
# It is linear and time-invariant: the reverb of a sum is the sum of the
# reverbs, which is what lets an offline render split its voices among
# processes that each run their own.
#
# An engine may run it elsewhere (the GPU engine, on the card): it reads the
# parameters and the lines' state from here, advances the positions here
# (advance), and leaves a way to fetch its state back (elsewhere), which
# process calls before it goes on in Perl. version changes whenever the
# lines are made anew or cleared: then what is here is what holds.

use v5.36;
use List::Util qw(max);

our $VERSION = '0.2610180';

# Line lengths in milliseconds at size 1: spread between 30 and 80 ms.
my @LENGTH_MS = (29.7, 37.1, 41.1, 43.7, 53.3, 59.9, 67.1, 79.3);

my %DEFAULT = (time => 2.2, size => 1.0, damp => 0.45, level => 0.5, predelay => 0.02, on => 1);

sub new ($class, %arg) {
    my $self = bless { rate => $arg{rate} // 48000, %DEFAULT }, $class;
    for my $name (keys %DEFAULT) { $self->{$name} = $arg{$name} if defined $arg{$name} }
    $self->_build;
    return $self;
}

sub params ($self) { return { map { $_ => $self->{$_} } keys %DEFAULT } }

sub set ($self, $name, $value) {
    die "the reverb has no '$name'\n" unless exists $DEFAULT{$name};
    $self->{$name} = $value;
    $self->_build if $name eq 'size' || $name eq 'predelay';
    $self->_gains;
    return $self;
}

sub _build ($self) {
    my $rate = $self->{rate};
    my @len  = map { int($_ / 1000 * $self->{size} * $rate) } @LENGTH_MS;
    $_ = 16 for grep { $_ < 16 } @len;
    my $pre  = int($self->{predelay} * $rate) || 1;

    # The lines and the predelay one after another in one buffer.
    my @offset;
    my $total = 0;
    for my $l (@len, $pre) {
        push @offset, $total;
        $total += $l;
    }
    $self->{len}     = \@len;
    $self->{pre}     = $pre;
    $self->{reach}   = $pre + max(@len);    # the longest way through
    $self->{offset}  = \@offset;
    $self->{buffer}  = [ (0.0) x $total ];
    $self->{pos}     = [ (0) x 9 ];
    $self->{lp}      = [ (0.0) x 8 ];
    $self->{since}   = $self->{reach};       # samples since anything went in
    $self->{loudest} = 0.0;
    $self->{clean}   = 1;
    $self->{version}++;
    delete $self->{elsewhere};
    $self->_gains;
    return;
}

sub _gains ($self) {
    my $rate = $self->{rate};
    $self->{g} = [ map { 10**(-3 * $_ / ($self->{time} * $rate)) } @{ $self->{len} } ];
    return;
}

# Whether the tail has died away: nothing has gone in for longer than the
# longest way through (the predelay and the longest line), and what came
# out of the last quantum is below -100 dB (before the master gain). A
# reverb that is off is always quiet.
sub quiet ($self) {
    return 1 unless $self->{on} && $self->{level} > 0;
    return $self->{since} >= $self->{reach} && $self->{loudest} < 1e-5;
}

sub clear ($self) {
    return $self if $self->{clean};
    $_ = 0.0 for @{ $self->{buffer} }, @{ $self->{lp} };
    $self->{since}   = $self->{reach};
    $self->{loudest} = 0.0;
    $self->{clean}   = 1;
    $self->{version}++;
    delete $self->{elsewhere};
    return $self;
}

# The reverb of $send (an array reference): left and right, as array
# references of the same length, or nothing when the reverb is off. They are
# fresh arrays, not added into the caller's: a loop that stores into two arrays
# that might be the same is one pperl's JIT leaves alone.
sub process ($self, $send) {
    return unless $self->{on} && $self->{level} > 0;
    if (my $back = delete $self->{elsewhere}) { $back->() }
    my $n = scalar @$send;
    my @wl = (0.0) x $n;
    my @wr = (0.0) x $n;
    my $d = $self->{buffer};
    my ($o0, $o1, $o2, $o3, $o4, $o5, $o6, $o7, $op) = @{ $self->{offset} };
    my ($l0, $l1, $l2, $l3, $l4, $l5, $l6, $l7) = @{ $self->{len} };
    my $lp_len = $self->{pre};
    my ($p0, $p1, $p2, $p3, $p4, $p5, $p6, $p7, $pp) = @{ $self->{pos} };
    my ($g0, $g1, $g2, $g3, $g4, $g5, $g6, $g7) = @{ $self->{g} };
    my ($s0, $s1, $s2, $s3, $s4, $s5, $s6, $s7) = @{ $self->{lp} };
    my $damp  = $self->{damp};
    my $keep  = 1.0 - $damp;
    my $level = $self->{level} * 0.35;
    my $loudest = 0.0;

    for my $i (0 .. $n - 1) {
        # The input, delayed.
        my $in = $d->[ $op + $pp ];
        $d->[ $op + $pp ] = $send->[$i];
        $pp++;
        $pp = 0 if $pp >= $lp_len;

        # The lines' outputs, damped.
        $s0 = $keep * $d->[ $o0 + $p0 ] + $damp * $s0;
        $s1 = $keep * $d->[ $o1 + $p1 ] + $damp * $s1;
        $s2 = $keep * $d->[ $o2 + $p2 ] + $damp * $s2;
        $s3 = $keep * $d->[ $o3 + $p3 ] + $damp * $s3;
        $s4 = $keep * $d->[ $o4 + $p4 ] + $damp * $s4;
        $s5 = $keep * $d->[ $o5 + $p5 ] + $damp * $s5;
        $s6 = $keep * $d->[ $o6 + $p6 ] + $damp * $s6;
        $s7 = $keep * $d->[ $o7 + $p7 ] + $damp * $s7;

        $wl[$i] = $level * ($s0 - $s1 + $s2 - $s3 + $s4 - $s5 + $s6 - $s7);
        $wr[$i] = $level * ($s0 + $s1 - $s2 - $s3 + $s4 + $s5 - $s6 - $s7);
        my $out = abs($wl[$i]) + abs($wr[$i]);
        $loudest = $out if $out > $loudest;

        # Hadamard 8x8, in three butterfly stages, scaled by 1/sqrt(8).
        my $a0 = $s0 + $s1; my $a1 = $s0 - $s1; my $a2 = $s2 + $s3; my $a3 = $s2 - $s3;
        my $a4 = $s4 + $s5; my $a5 = $s4 - $s5; my $a6 = $s6 + $s7; my $a7 = $s6 - $s7;
        my $b0 = $a0 + $a2; my $b1 = $a1 + $a3; my $b2 = $a0 - $a2; my $b3 = $a1 - $a3;
        my $b4 = $a4 + $a6; my $b5 = $a5 + $a7; my $b6 = $a4 - $a6; my $b7 = $a5 - $a7;
        my $h = 0.35355339059327373;
        $d->[ $o0 + $p0 ] = $g0 * (($b0 + $b4) * $h + $in);
        $d->[ $o1 + $p1 ] = $g1 * (($b1 + $b5) * $h + $in);
        $d->[ $o2 + $p2 ] = $g2 * (($b2 + $b6) * $h + $in);
        $d->[ $o3 + $p3 ] = $g3 * (($b3 + $b7) * $h + $in);
        $d->[ $o4 + $p4 ] = $g4 * (($b0 - $b4) * $h - $in);
        $d->[ $o5 + $p5 ] = $g5 * (($b1 - $b5) * $h - $in);
        $d->[ $o6 + $p6 ] = $g6 * (($b2 - $b6) * $h - $in);
        $d->[ $o7 + $p7 ] = $g7 * (($b3 - $b7) * $h - $in);

        $p0++; $p0 = 0 if $p0 >= $l0;
        $p1++; $p1 = 0 if $p1 >= $l1;
        $p2++; $p2 = 0 if $p2 >= $l2;
        $p3++; $p3 = 0 if $p3 >= $l3;
        $p4++; $p4 = 0 if $p4 >= $l4;
        $p5++; $p5 = 0 if $p5 >= $l5;
        $p6++; $p6 = 0 if $p6 >= $l6;
        $p7++; $p7 = 0 if $p7 >= $l7;
    }
    $self->{pos} = [ $p0, $p1, $p2, $p3, $p4, $p5, $p6, $p7, $pp ];
    $self->{lp}  = [ $s0, $s1, $s2, $s3, $s4, $s5, $s6, $s7 ];
    $self->{loudest} = $loudest;
    $self->_fed($send);
    return (\@wl, \@wr);
}

# The input of a quantum: how long ago it last had anything in it.
sub _fed ($self, $send) {
    my $i = $#$send;
    $i-- while $i >= 0 && $send->[$i] == 0;
    $self->{since} = $i < 0 ? $self->{since} + @$send : $#$send - $i;
    $self->{clean} = 0;
    return;
}

# Whether it sounds at all.
sub active ($self) { return $self->{on} && $self->{level} > 0 ? 1 : 0 }

# After $n samples processed elsewhere, their send and wet left and right:
# the positions moved on, the input and the loudest noted (for quiet).
sub advance ($self, $n, $send, $wl, $wr) {
    my @len = (@{ $self->{len} }, $self->{pre});
    my $pos = $self->{pos};
    $pos->[$_] = ($pos->[$_] + $n) % $len[$_] for 0 .. 8;
    my $loudest = 0.0;
    for my $i (0 .. $n - 1) {
        my $out = abs($wl->[$i]) + abs($wr->[$i]);
        $loudest = $out if $out > $loudest;
    }
    $self->{loudest} = $loudest;
    $self->_fed($send);
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Synth::Reverb - a feedback delay network reverb

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $reverb = Peta::Synth::Reverb->new(rate => 48000, time => 2.5);
    my ($wet_left, $wet_right) = $reverb->process(\@send);
    $reverb->set(damp => 0.6);

=head1 DESCRIPTION

Eight delay lines fed back through a Hadamard matrix, damped and attenuated
to fall 60 dB in the reverb time. The input is the voices' reverb send
(each channel's CC91); left and right come out decorrelated.

=head1 METHODS

=head2 new

C<< new(rate => ..., time => 2.2, size => 1, damp => 0.45, level => 0.5, predelay => 0.02, on => 1) >>.
C<time> is the reverb time (s), C<size> scales the delay lines, C<damp>
(0 .. 1) how quickly the highs die, C<level> the wet level.

=head2 set, params

Changes one parameter while it runs; all of them as a hash.

=head2 process

C<process(\@send)>: the reverb of the send, as left and right array
references, or nothing when it is off.

=head2 active, advance

Whether it sounds (on, and a level above 0). C<advance($n, \@send,
\@wet_left, \@wet_right)>: what an engine that ran it elsewhere reports.

=head2 quiet

Whether the tail has died away: nothing has gone in for longer than the
predelay and the longest line, and the last quantum came out below -100 dB.

=head2 clear

Silences the tail.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
