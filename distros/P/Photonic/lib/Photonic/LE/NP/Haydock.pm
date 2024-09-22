package Photonic::LE::NP::Haydock;
$Photonic::LE::NP::Haydock::VERSION = '0.022';

=encoding UTF-8

=head1 NAME

Photonic::LE::NP::Haydock

=head1 VERSION

version 0.022

=head1 COPYRIGHT NOTICE

Photonic - A perl package for calculations on photonics and
metamaterials.

Copyright (C) 2016 by W. Luis Mochán

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 1, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA  02110-1301 USA

    mochan@fis.unam.mx

    Instituto de Ciencias Físicas, UNAM
    Apartado Postal 48-3
    62251 Cuernavaca, Morelos
    México

=cut

=head1 VERSION

version 0.022

=head1 SYNOPSIS

    use Photonic::LE::NP::Haydock;
    my $nr=Photonic::LE::NP::Haydock->new(epsilon=>$epsilon,
           geometry=>$geometry);
    $nr->iterate;
    say $nr->iteration;
    say $nr->current_a;
    say $nr->next_b2;
    my $state=$nr->next_state;

=head1 DESCRIPTION

Implements calculation of Haydock coefficients and Haydock states for
the calculation of the non retarded dielectric function of arbitrary
periodic many component systems in arbitrary number of dimentions. One
Haydock coefficient at a time. The starting state is homogenous.

Warning: this module is fragile and depends on a particular initial state.

Consumes L<Photonic::Roles::Haydock>, L<Photonic::Roles::EpsFromGeometry>
- please see those for attributes.

=head1 ATTRIBUTES SUPPLIED FOR ROLE

These are provided for roles:

=over 4

=item * geometry

A L<Photonic::Types/GeometryG0> object defining the geometry of the system,
the characteristic function and the direction of the G=0 vector. Required.

=item * B ndims dims r G GNorm L scale f

Accessors handled by geometry (see L<Photonic::Geometry>)

=item * applyOperator

Apply the 'Hamiltonian' operator to state $psi_G in reciprocal
space. State is nx:ny...  The operator is the
longitudinal projection of the dielectric function

=item * innerProduct

Returns the inner (Euclidean) product between states $left and $right.

=item * magnitude

Returns the magnitude of state $psi_G in reciprocal space by taking the
square root of the inner product of the state with itself.

=item * changesign

Returns zero, as there is no need to change sign.

=item * complexCoeffs

Haydock coefficients are complex

=back

=cut

use namespace::autoclean;
use PDL::Lite;
use Carp;
use Photonic::Types -all;
use Photonic::Utils qw(EProd any_complex apply_longitudinal_projection);
use Moo;
use MooX::StrictConstructor;

has 'geometry'=>(is=>'ro', isa => GeometryG0,
    handles=>[qw(B ndims dims r G GNorm L scale f)],required=>1
);
has 'complexCoeffs'=>(is=>'ro', init_arg=>undef, default=>1,
		      documentation=>'Haydock coefficients are complex');
with 'Photonic::Roles::Haydock', 'Photonic::Roles::EpsFromGeometry';

sub _build_firstState { #\delta_{G0}
    my $self=shift;
    my $v=PDL->zeroes(@{$self->dims})->r2C; #nx, ny...
    my $arg=join ',', ("(0)") x ($self->B->ndims); #(0),(0),... ndims+1 times
    $v->slice($arg).=1; #i*delta_{G0}
    return $v;
}

sub applyOperator {
    my $self=shift;
    my $psi_G=shift;
    confess "State should be complex" unless any_complex($psi_G);
    apply_longitudinal_projection($psi_G, $self->GNorm, $self->ndims, $self->epsilon);
}

sub innerProduct {
    #ignore self
    my $self=shift;
    my $left=shift;
    my $right=shift;
    my $p=EProd($left, $right);
    # this is a dirty hack. Only the initial state is even in k+G. The
    # rest are odd.
    # The trick works, but is not robust and if non orthogonal states
    # are generated may give TROUBLE. Better use spinor methods,
    # though they take longer.
    $p=-$p unless PDL::all($left->slice('(0),(0)')->re == 1); #unless initial state
    return $p;
}

sub magnitude {
    my $self=shift;
    my $psi=shift;
    return $self->innerProduct($psi, $psi)->abs->sqrt;
}
sub changesign { # change sign
    return 0;
}

__PACKAGE__->meta->make_immutable;

1;
