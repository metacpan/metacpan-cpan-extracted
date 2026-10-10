package Peta::NN::RNG;
# ABSTRACT: seeded random numbers that are the same on every perl

# A small seeded generator of our own, not perl's rand(): initial weights and
# the shuffle order must be the same on every perl and every run, or a trained
# model cannot be reproduced and test thresholds cannot be exact.

use v5.36;

our $VERSION = '0.2610090';

my $MODULUS    = 2_147_483_647;    # 2**31 - 1, the Park-Miller "minimal standard"
my $MULTIPLIER = 48_271;           # state * multiplier stays below 2**47: exact in an IV
my $TWO_PI     = 6.283185307179586;

sub new ($class, $seed = 1) {
    my $state = int($seed) % $MODULUS;
    $state = 1 if $state <= 0;
    return bless { state => $state }, $class;
}

# Uniform in the open interval (0, 1).
sub uniform ($self) {
    $self->{state} = ($self->{state} * $MULTIPLIER) % $MODULUS;
    return $self->{state} / $MODULUS;
}

# Uniform integer in 0 .. $n-1.
sub below ($self, $n) {
    return int($self->uniform * $n);
}

# Standard normal, Box-Muller.
sub normal ($self) {
    return sqrt(-2 * log($self->uniform)) * cos($TWO_PI * $self->uniform);
}

# Fisher-Yates, in place.
sub shuffle ($self, $list) {
    for my $i (reverse 1 .. $#$list) {
        my $j = $self->below($i + 1);
        @$list[$i, $j] = @$list[$j, $i];
    }
    return $list;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::NN::RNG - seeded random numbers that are the same on every perl

=head1 VERSION

version 0.2610090

=head1 SYNOPSIS

    my $rng = Peta::NN::RNG->new(42);
    my $u   = $rng->uniform;        # (0, 1)
    my $k   = $rng->below(10);      # 0 .. 9
    my $z   = $rng->normal;         # mean 0, deviation 1
    $rng->shuffle(\@order);

=head1 METHODS

=head2 new

C<< Peta::NN::RNG->new($seed) >>; the seed defaults to 1.

=head2 uniform

A number in the open interval (0, 1).

=head2 below

C<below($n)>: a whole number from 0 to C<$n - 1>.

=head2 normal

A standard normal number.

=head2 shuffle

C<shuffle(\@list)>: shuffles the list in place.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
