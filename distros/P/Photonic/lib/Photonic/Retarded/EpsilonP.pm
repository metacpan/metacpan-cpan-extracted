=head1 NAME

Photonic::Retarded::EpsilonP

=head1 VERSION

version 0.009

=head1 SYNOPSIS

   use Photonic::Retarded::EpsilonP;
   my $eps=Photonic::Retarded::EpsilonP->new(haydock=>$h, nh=>$nh);
   my $EpsTensor=$W->evaluate($epsB);

=head1 DESCRIPTION

Calculates the macroscopic dielectric tensor component for a given fixed
Photonic::Retarded::AllH structure as a function of the dielectric
functions of the components.

NOTE: Only works for polarizations along principal directions.

=head1 METHODS

=over 4

=item * new(haydock=>$h, nh=>$nh, smallE=>$smallE)  

Initializes the structure.

$h Photonic::Retarded::AllH describing the structure and some parametres.

$nh is the maximum number of Haydock coefficients to use.

$smallE is the criterium of convergence (default 1e-7) for
Haydock coefficients and for the continued fraction. From
Photonic::Roles::EpsParams.  

$k is a flag to keep states in Haydock calculations (default 0)

=item * evaluate($epsB)

Returns the macroscopic dielectric component for a given value of the
dielectric function of the particle $epsB. The host's
response $epsA is taken from the AllH structure.  

NOTE: Only works along principal directions.

=back

=head1 ACCESORS (read only)

=over 4

=item * epsilon

The macroscopic dielectric projection of the last operation

=item * All accesors of Photonic::Retarded::Wave


=back

=cut

package Photonic::Retarded::EpsilonP;
$Photonic::Retarded::EpsilonP::VERSION = '0.009';
use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use PDL::Complex;
use PDL::MatrixOps;
#use Storable qw(dclone);
#use PDL::IO::Storable;
#use Photonic::Retarded::AllH;
use Moose;
use Photonic::Types;

extends 'Photonic::Retarded::WaveP'; 

has 'epsilon' =>  (is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
             writer=>'_epsilon',   
             documentation=>'Wave projection from last evaluation');

around 'evaluate' => sub {
    my $orig=shift;
    my $self=shift;
    my $wave=$self->$orig(@_);
    my $q=$self->haydock->metric->wavenumber;
    my $q2=$q*$q;
    my $k=$self->haydock->metric->wavevector;
    my $k2=$k->inner($k);
    #my $kk=$k->outer($k);
    my $p=$self->haydock->normalizedPolarization;
    #Note $p->inner($p) might be complex, so is not necessarily 1.
    my $p2=($p*$p)->sumover;
    my $pk=($p*$k)->sumover;
    my $proj=$p2*$k2/$q2 - $pk*$pk/$q2;
    my $eps=$wave+$proj;
    $self->_epsilon($eps);
    return $eps;
};

__PACKAGE__->meta->make_immutable;
    
1;

__END__
