=head1 NAME

Photonic::Retarded::WaveP

=head1 VERSION

version 0.009

=head1 SYNOPSIS

   use Photonic::Retarded::WaveP;
   my $W=Photonic::Retarded::WaveP->new(haydock=>$h, nh=>$nh, smallE=>$s);
   my $WaveProjection=$W->evaluate($epsB);

=head1 DESCRIPTION

Calculates the macroscopic projected wave operator for a given fixed
Photonic::Retarded::AllH structure as a function of the dielectric
functions of the components. 

NOTE: Only works along principal directions, as it treats Green's
function as scalar.  

=head1 METHODS

=over 4

=item * new(haydock=>$h, nh=>$nh, smallE=>$smallE)  

Initializes the structure.

$h is Photonic::Retarded::AllH structure (required).

$nh is the maximum number of Haydock coefficients to use (required).

$smallE is the criteria of convergence (default 1e-7).

=item * evaluate($epsB)

Returns the macroscopic wave operator for a given value of the
dielectric functions of the particle $epsB. The host's
response $epsA is taken from the metric.  

=back

=head1 ACCESORS (read only)

=over 4

=item * waveOperator

The macroscopic wave operator of the last operation

=item * All accesors of Photonic::Retarded::GreenP


=back

=cut

package Photonic::Retarded::WaveP;
$Photonic::Retarded::WaveP::VERSION = '0.009';
use namespace::autoclean;
use PDL::Lite;
use PDL::NiceSlice;
use PDL::Complex;
#use PDL::MatrixOps;
use Storable qw(dclone);
use PDL::IO::Storable;
#use Photonic::Retarded::AllH;
use Moose;
use Photonic::Types;

extends 'Photonic::Retarded::GreenP'; 

has 'waveOperator' =>  (is=>'ro', isa=>'PDL::Complex', init_arg=>undef,
             writer=>'_waveOperator',   
             documentation=>'Wave operator from last evaluation');

around 'evaluate' => sub {
    my $orig=shift;
    my $self=shift;
    my $greenP=$self->$orig(@_);
    my $wave=1/$greenP; #only works along principal directions!!
    $self->_waveOperator($wave);
    return $wave;
};

__PACKAGE__->meta->make_immutable;
    
1;

__END__
