package Photonic::WE::R2::Wave;
$Photonic::WE::R2::Wave::VERSION = '0.011';

=encoding UTF-8

=head1 NAME

Photonic::WE::R2::Wave

=head1 VERSION

version 0.011

=head1 COPYRIGHT NOTICE

Photonic - A perl package for calculations on photonics and
metamaterials.

Copyright (C) 1916 by W. Luis Mochán

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

   use Photonic::WE::R2::Wave;
   my $W=Photonic::WE::R2::Wave->new(metric=>$m, nh=>$nh);
   my $WaveTensor=$W->evaluate($epsB);

=head1 DESCRIPTION

Calculates the macroscopic wave operator for a given fixed
Photonic::WE::R2::Metric structure as a function of the dielectric
functions of the components.

=head1 METHODS

=over 4

=item * new(metric=>$m, nh=>$nh, smallH=>$smallH, smallE=>$smallE, keepStates=>$k)

Initializes the structure.

$m Photonic::WE::R2::Metric describing the structure and some parametres.

$nh is the maximum number of Haydock coefficients to use.

$smallH and $smallE are the criteria of convergence (default 1e-7) for
Haydock coefficients and for continued fraction.

$k is a flag to keep states in Haydock calculations (default 0)

=item * evaluate($epsB)

Returns the macroscopic wave operator for a given value of the
dielectric functions of the particle $epsB. The host's
response $epsA is taken from the metric.

=back

=head1 ACCESORS (read only)

=over 4

=item * waveOperator

The macroscopic wave operator of the last operation

=item * All accesors of L<Photonic::WE::R2::Green>

=back

=cut

use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use PDL::Complex;
use PDL::MatrixOps;
use Storable qw(dclone store);
use PDL::IO::Storable;
#use Photonic::WE::R2::AllH;
use Photonic::Types;
use Moose;
use MooseX::StrictConstructor;

extends 'Photonic::WE::R2::Green';

has 'waveOperator' =>  (is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
             writer=>'_waveOperator',
             documentation=>'Wave operator from last evaluation');

around 'evaluate' => sub {
    my $orig=shift;
    my $self=shift;
    my $green=$self->$orig(@_);
    #make a real matrix from [[R -I][I R]] to solve complex eq.
    my $greenreim=$green->re->append(-$green->im)
       ->glue(1,$green->im->append($green->re))->sever; #copy vs sever?
    my($lu, $perm, $par)=$greenreim->lu_decomp;
    my $d=$self->geometry->ndims;
    my $idreim=identity($d)->glue(1,PDL->zeroes($d,$d))->mv(0,-1);
    my $wavereim=lu_backsub($lu,$perm,$par,$idreim);
    my $wave=$wavereim->reshape($d,2,$d)->mv(1,0)->complex;
    $self->_waveOperator($wave);
    return $wave;
};

__PACKAGE__->meta->make_immutable;

1;
