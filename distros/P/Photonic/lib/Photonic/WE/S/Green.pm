package Photonic::WE::S::Green;
$Photonic::WE::S::Green::VERSION = '0.024';

=encoding UTF-8

=head1 NAME

Photonic::WE::S::Green

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

   use Photonic::WE::S::Green;
   my $G=Photonic::WE::S::Green->new(metric=>$m, nh=>$nh);
   my $GreenTensor=$G->greenTensor;
   my $WaveTensor=$G->waveOperator;
   my $EpsTensor=$G->epsilonTensor;

=head1 DESCRIPTION

Calculates the retarded green's tensor for a given fixed
Photonic::WE::S::Metric structure as a function of the dielectric
functions of the components.

=head1 ATTRIBUTES

=over 4

=item * keepStates

Value of flag to keep Haydock states in Haydock calculations (default 0)

=item * metric

L<Photonic::WE::S::Metric> describing the structure and some parameters.

=item * nh

The maximum number of Haydock coefficients to use.

=item * smallH, smallE

Criteria of convergence of Haydock coefficients and continued
fraction. 0 means don't check. (default 1e-7)

=item * haydock

Array of L<Photonic::WE::S::Haydock> structures, one for each polarization

=item * reorthogonalize

Reorthogonalize haydock flag

=item * greenP

Array of L<Photonic::WE::S::GreenP> structures, one for each direction.

=item * greenTensor

The Green's tensor calculated

=item * nhActual

The actual number of Haydock coefficients used in the last calculation

=item * converged

Flags that the last calculation converged before using up all coefficients

=item * waveOperator

The macroscopic wave operator of the last operation

=item * epsilonTensor

The macroscopic dielectric tensor

=back

=cut

use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use Photonic::WE::S::Haydock;
use Photonic::WE::S::GreenP;
use Photonic::Types -all;
use Photonic::Utils qw(tensor make_haydock make_greenp wave_operator any_complex);
use List::Util qw(all);
use Moo;
use MooX::StrictConstructor;

has 'nh' =>(is=>'ro', isa=>Num, required=>1,
	    documentation=>'Desired no. of Haydock coefficients');
has 'smallH'=>(is=>'ro', isa=>Num, required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for Haydock coefficients');
has 'smallE'=>(is=>'ro', isa=>Num, required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for use of Haydock coeff.');
has 'metric'=>(is=>'ro', isa => InstanceOf['Photonic::WE::S::Metric'],
       handles=>[qw(geometry ndims dims)],required=>1);

has 'haydock' =>(is=>'lazy', isa=>ArrayRef[Haydock],
            init_arg=>undef,
	    documentation=>'Array of Haydock calculators');
has 'greenP'=>(is=>'lazy', isa=>ArrayRef[InstanceOf['Photonic::WE::S::GreenP']],
             init_arg=>undef,
             documentation=>'Array of projected G calculators');
has 'converged'=>(is=>'ro', init_arg=>undef, writer=>'_converged',
             documentation=>
                  'All greenP evaluations converged');
has 'greenTensor'=>(is=>'lazy', isa=>PDLComplex, init_arg=>undef,
             documentation=>'Greens Tensor');
has 'reorthogonalize'=>(is=>'ro', required=>1, default=>0,
         documentation=>'Reorthogonalize haydock flag');
has 'waveOperator' =>  (is=>'lazy', isa=>PDLComplex, init_arg=>undef,
                        documentation=>'Wave operator');
has 'epsilonTensor' =>  (is=>'lazy', isa=>PDLComplex, init_arg=>undef,
                         documentation=>'macroscopic response');

with 'Photonic::Roles::KeepStates', 'Photonic::Roles::UseMask';

#  Antisymmetric part is missing. Compare to ST and to R2!

sub _build_greenTensor {
    my $self=shift;
    $self->_converged(all { $_->converged } @{$self->greenP});
    tensor(pdl([map $_->Gpp, @{$self->greenP}]), $self->geometry->unitDyadsLU, $self->geometry->ndims, 2);
}

sub _build_haydock { # One Haydock coefficients calculator per direction0
    my ($self) = @_;
    make_haydock($self, 'Photonic::WE::S::Haydock', $self->geometry->unitPairs, 0, qw(reorthogonalize use_mask mask));
}

sub _build_greenP {
    make_greenp(shift, 'Photonic::WE::S::GreenP');
}

sub _build_waveOperator {
    my $self=shift;
    wave_operator($self->greenTensor, $self->geometry->ndims);
}

sub _build_epsilonTensor {
    my $self=shift;
    my $wave=$self->waveOperator;
    my $q=$self->metric->wavenumber;
    my $q2=$q*$q;
    my $k=$self->metric->wavevector;
    my ($k2, $kk);
    if(any_complex($q, $k)){
        #Make both complex
        $_ = PDL::r2C($_) for $q, $k;
        $k2=($k*$k)->sumover; #inner
        $kk=$k->(:,*1)*$k->(*1); #outer
    } else {
        $k2=$k->inner($k);
        $kk=$k->outer($k);
    }
    my $id=PDL::MatrixOps::identity($k);
    $wave+$k2/$q2*$id - $kk/$q2;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
