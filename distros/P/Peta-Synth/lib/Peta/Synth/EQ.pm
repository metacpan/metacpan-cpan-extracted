package Peta::Synth::EQ;
# ABSTRACT: the master equalizer

# The master equalizer: four bands of biquad filters (R. Bristow-Johnson's
# cookbook) on both channels.
#
#   low    a low shelf       (100 Hz)
#   mid1   a peaking band    (400 Hz)
#   mid2   a peaking band    (2.5 kHz)
#   high   a high shelf      (8 kHz)
#
# Each band has a frequency, a gain in dB (-12 .. 12) and, for the peaking
# bands, a Q. A band at 0 dB is left out; all at 0 dB, the equalizer
# passes the sound untouched. Linear and time-invariant, so it may run on
# parts of a mix that are added up afterwards.

use v5.36;

our $VERSION = '0.2610180';

use constant PI => 3.141592653589793;

my @BANDS = (
    [ low  => 'lowshelf',  100,  0.71 ],
    [ mid1 => 'peak',      400,  1.0 ],
    [ mid2 => 'peak',      2500, 1.0 ],
    [ high => 'highshelf', 8000, 0.71 ],
);
my %RANGE = (freq => [ 20, 20000 ], gain => [ -12, 12 ], q => [ 0.3, 8 ]);

sub new ($class, %arg) {
    my $self = bless { rate => $arg{rate} // 48000, bands => {} }, $class;
    for my $b (@BANDS) {
        my ($name, $type, $freq, $q) = @$b;
        my $band = $self->{bands}{$name} = {
            type  => $type,
            freq  => $freq,
            gain  => 0,
            q     => $q,
            state => [ 0.0, 0.0, 0.0, 0.0 ],    # the filter's, left and right
        };
        $self->_coefficients($band);
    }
    $self->set(%{ $arg{bands} // {} });
    return $self;
}

sub names () { return map { $_->[0] } @BANDS }
sub range ($what) { return @{ $RANGE{$what} } }

# set(low => { gain => 3 }, mid2 => { freq => 3000, q => 2 }, ...)
sub set ($self, %bands) {
    for my $name (keys %bands) {
        my $band = $self->{bands}{$name} // die "the equalizer has no band '$name'\n";
        for my $what (keys %{ $bands{$name} }) {
            my $range = $RANGE{$what} // die "an equalizer band has no '$what'\n";
            my $v = 0 + $bands{$name}{$what};
            $v = $range->[0] if $v < $range->[0];
            $v = $range->[1] if $v > $range->[1];
            $band->{$what} = $v;
        }
        $band->{state} = [ 0.0, 0.0, 0.0, 0.0 ] if $band->{gain} != 0 && !$band->{on};    # back from 0 dB: not what it held then
        $band->{on} = $band->{gain} != 0;
        $self->_coefficients($band);
    }
    return $self;
}

# { band => { freq, gain, q } }
sub params ($self) {
    my %params;
    for my $name (names()) {
        my $band = $self->{bands}{$name};
        $params{$name} = { freq => $band->{freq}, gain => $band->{gain}, q => $band->{q} };
    }
    return \%params;
}

# Whether it changes anything.
sub active ($self) { return scalar grep { $_->{gain} != 0 } values %{ $self->{bands} } }

sub clear ($self) {
    $_->{state} = [ 0.0, 0.0, 0.0, 0.0 ] for values %{ $self->{bands} };
    return;
}

# Whether the filters have rung out: what they hold is below -200 dB.
sub quiet ($self) {
    for my $band (values %{ $self->{bands} }) {
        return 0 if grep { abs $_ > 1e-10 } @{ $band->{state} };
    }
    return 1;
}

# The cookbook's coefficients, normalized by a0: [b0, b1, b2, a1, a2].
sub _coefficients ($self, $band) {
    my $A  = 10**($band->{gain} / 40);
    my $w0 = 2 * PI * $band->{freq} / $self->{rate};
    $w0 = PI * 0.99 if $w0 > PI * 0.99;
    my ($cos, $sin) = (cos $w0, sin $w0);
    my $alpha = $sin / (2 * $band->{q});
    my $s     = 2 * sqrt($A) * $alpha;    # the shelves'
    my ($b0, $b1, $b2, $a0, $a1, $a2);
    if ($band->{type} eq 'peak') {
        $b0 = 1 + $alpha * $A;
        $b1 = -2 * $cos;
        $b2 = 1 - $alpha * $A;
        $a0 = 1 + $alpha / $A;
        $a1 = -2 * $cos;
        $a2 = 1 - $alpha / $A;
    }
    elsif ($band->{type} eq 'lowshelf') {
        $b0 = $A * (($A + 1) - ($A - 1) * $cos + $s);
        $b1 = 2 * $A * (($A - 1) - ($A + 1) * $cos);
        $b2 = $A * (($A + 1) - ($A - 1) * $cos - $s);
        $a0 = ($A + 1) + ($A - 1) * $cos + $s;
        $a1 = -2 * (($A - 1) + ($A + 1) * $cos);
        $a2 = ($A + 1) + ($A - 1) * $cos - $s;
    }
    else {
        $b0 = $A * (($A + 1) + ($A - 1) * $cos + $s);
        $b1 = -2 * $A * (($A - 1) + ($A + 1) * $cos);
        $b2 = $A * (($A + 1) + ($A - 1) * $cos - $s);
        $a0 = ($A + 1) - ($A - 1) * $cos + $s;
        $a1 = 2 * (($A - 1) - ($A + 1) * $cos);
        $a2 = ($A + 1) - ($A - 1) * $cos - $s;
    }
    $band->{coef} = [ $b0 / $a0, $b1 / $a0, $b2 / $a0, $a1 / $a0, $a2 / $a0 ];
    return;
}

# The response in dB at a frequency, all bands together: for drawing it.
sub response ($self, $freq) {
    my $w = 2 * PI * $freq / $self->{rate};
    my $db = 0;
    for my $band (values %{ $self->{bands} }) {
        next if $band->{gain} == 0;
        my ($b0, $b1, $b2, $a1, $a2) = @{ $band->{coef} };
        my ($c1, $s1, $c2, $s2) = (cos $w, sin $w, cos(2 * $w), sin(2 * $w));
        my ($nr, $ni) = ($b0 + $b1 * $c1 + $b2 * $c2, -$b1 * $s1 - $b2 * $s2);
        my ($dr, $di) = (1 + $a1 * $c1 + $a2 * $c2, -$a1 * $s1 - $a2 * $s2);
        $db += 10 * log(($nr * $nr + $ni * $ni) / ($dr * $dr + $di * $di)) / log(10);
    }
    return $db;
}

# Both channels through the bands that are not at 0 dB: fresh arrays.
sub process ($self, $left, $right) {
    my @l = @$left;
    my @r = @$right;
    for my $name (names()) {
        my $band = $self->{bands}{$name};
        next if $band->{gain} == 0;
        my ($b0, $b1, $b2, $a1, $a2) = @{ $band->{coef} };
        my ($l1, $l2, $r1, $r2) = @{ $band->{state} };    # transposed direct form II
        for my $i (0 .. $#l) {
            my $x = $l[$i];
            my $y = $b0 * $x + $l1;
            $l1 = $b1 * $x - $a1 * $y + $l2;
            $l2 = $b2 * $x - $a2 * $y;
            $l[$i] = $y;
            $x = $r[$i];
            $y = $b0 * $x + $r1;
            $r1 = $b1 * $x - $a1 * $y + $r2;
            $r2 = $b2 * $x - $a2 * $y;
            $r[$i] = $y;
        }
        $band->{state} = [ $l1, $l2, $r1, $r2 ];
    }
    return (\@l, \@r);
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Synth::EQ - the master equalizer

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $eq = Peta::Synth::EQ->new(rate => 48000);
    $eq->set(low => { gain => 3 }, high => { gain => -2, freq => 6000 });
    my ($l, $r) = $eq->process(\@left, \@right);

=head1 DESCRIPTION

Four bands of biquads: a low shelf, two peaking bands and a high shelf,
each with a frequency, a gain of -12 to 12 dB and (peaking bands) a Q. Bands
at 0 dB cost nothing.

=head1 METHODS

=head2 new

C<new(rate =E<gt> 48000, bands =E<gt> { ... })>: all bands at 0 dB, then
C<bands> as for C<set>.

=head2 set

C<set(low =E<gt> { gain =E<gt> 3 }, mid2 =E<gt> { freq =E<gt> 3000, q =E<gt> 2 })>:
the bands' frequency, gain or Q, each held within its range. Returns the
equalizer.

=head2 params

C<{ low =E<gt> { freq, gain, q }, ... }>: the bands as they are set.

=head2 clear

Forgets the sound so far: the filters start from silence again.

=head2 active

Whether any band is not at 0 dB.

=head2 quiet

Whether the filters have rung out (what they hold is below -200 dB).

=head2 response

The response in dB at a frequency.

=head2 process

C<process(\@left, \@right)>: the sound through the bands; fresh arrays.

=head1 FUNCTIONS

=head2 names, range

The bands' names; the range of C<freq>, C<gain> or C<q>.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
