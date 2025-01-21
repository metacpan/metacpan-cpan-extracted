package PolyNomial;

use PDL::Lite;

use Moo;
extends 'MooX::PDL2';

has x => (
    is       => 'rw',
    required => 1,
    trigger  => sub { $_[0]->_clear_PDL },
);

has coeffs => (
    is       => 'rw',
    required => 1,
    trigger  => sub { $_[0]->_clear_PDL },
);

sub _build__PDL {

    my $self = shift;

    my $x     = $self->x;
    my $coeff = $self->coeffs;

    # this calculation is not robust at all
    my $pdl = $x->ones;
    $pdl *= $coeff->[0];

    $pdl += $coeff->[$_] * $x**$_
      for 1..@$coeff-1;

    $pdl;
}

1;
