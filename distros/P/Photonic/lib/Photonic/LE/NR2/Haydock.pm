package Photonic::LE::NR2::Haydock;
$Photonic::LE::NR2::Haydock::VERSION = '0.024';

=encoding UTF-8

=head1 NAME

Photonic::LE::NR2::Haydock;

=head1 VERSION

version 0.024

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

=head1 SYNOPSIS

    use Photonic::LE::NR2::Haydock;
    my $nr=Photonic::LE::NR2::Haydock->new(geometry=>$geometry);
    $nr->iterate;
    say $nr->iteration;
    say $nr->current_a;
    say $nr->next_b2;
    my $state=$nr->next_state;

=head1 DESCRIPTION

Implements calculation of Haydock coefficients and Haydock states for
the calculation of the non retarded dielectric function of arbitrary
periodic two component systems in arbitrary number of dimentions. One
Haydock coefficient at a time.

Consumes L<Photonic::Roles::Haydock>, L<Photonic::Roles::UseMask>
- please see those for attributes.

=head1 ATTRIBUTES

=over 4

=item * geometry

A L<Photonic::Types/GeometryG0> object defining the geometry of the system,
the characteristic function and the direction of the G=0 vector. Required.

=item * B ndims dims r G GNorm L scale f

Accessors handled by geometry (see Photonic::Roles::Geometry)

=back

=head1 ATTRIBUTES SUPPLIED FOR ROLE

These are provided for roles:

=over 4

=item * applyOperator($psi_G)

Apply the 'Hamiltonian' operator to state. State is
nx:ny... gnorm=i:nx:ny... The operator is the longitudinal
=component of the characteristic function.

=item * innerProduct($left, $right)

Returns the inner (Hermitian) product between states.

=item * magnitude($psi)

Returns the magnitude of a state as the square root of the inner
=product of the state with itself.

=item * changesign

Return 0, as there is no need to change sign.

=item * complexCoeffs

Haydock coefficients are real

=back

=cut

use namespace::autoclean;
use PDL::Lite;
use Carp;
use Photonic::Types -all;
use Photonic::Utils qw(HProd apply_longitudinal_projection);
use Moo;
use MooX::StrictConstructor;

has 'geometry'=>(is=>'ro', isa => GeometryG0,
    handles=>[qw(B dims ndims r G GNorm L scale f)],required=>1);
has 'complexCoeffs'=>(is=>'ro', init_arg=>undef, default=>0,
		      documentation=>'Haydock coefficients are real');
with 'Photonic::Roles::Haydock', 'Photonic::Roles::UseMask';

sub _build_firstState { #\delta_{G0}
    my $self=shift;
    my $v=PDL->zeroes(@{$self->dims})->r2C; #nx, ny...
    my $arg=join ',', ("(0)") x ($self->ndims); #(0),(0),... ndims times
    $v->slice($arg).=1; #delta_{G0}
    return $v;
}

sub applyOperator {
    my $self=shift;
    my $psi_G=shift;
    my $GBGpsi_G=apply_longitudinal_projection($psi_G, $self->GNorm, $self->ndims, $self->B->r2C);
    my $mask = $self->mask;
    $GBGpsi_G *= $mask if defined $mask and $self->use_mask;
    return $GBGpsi_G;
}

sub innerProduct {
    return HProd(@_[1,2], $_[0]->ndims); #skip self, Hermitian product
}

sub magnitude { #magnitude of a state
    return  sqrt($_[1]->abs2->sum);
    #could be innerProduct($_[1], $_[1]);
}

sub changesign { #don't change sign
    return 0;
}

__PACKAGE__->meta->make_immutable;

1;
