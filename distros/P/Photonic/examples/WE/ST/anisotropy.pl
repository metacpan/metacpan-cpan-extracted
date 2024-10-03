# Obtain the Green's function for the wave equation and the dielectric tensor
# for a Bouligand-like structure of 3 repeated and rotated anisotropic layers.
use v5.36;
use PDL;
use PDL::NiceSlice;
use PDL::Constants qw(PI);
use Photonic::Geometry::FromEpsilonTensor;
use Photonic::WE::ST::Metric;
use Photonic::WE::ST::Haydock;
use Photonic::WE::ST::Green;
use Photonic::WE::ST::GreenP;
my $nh=10;
my $rot=pdl[[cos(2*PI/3), -sin(2*PI/3), 0],
	     [sin(2*PI/3),  cos(2*PI/3), 0],
	     [0,            0,           1]];
my $ea=(pdl[[2,0,0],
	   [0,1,0],
	   [0,0,1]])->r2C;
my $eb=$rot x $ea x $rot->transpose;
my $ec=$rot x $eb x $rot->transpose;
my $epsilon=pdl($ea, $eb, $ec)  # j,i,nz
    ->(:,:,*1,*1); # j,i,nx,ny,nz
my $epsilonRef=pdl(1);
my $geometry=Photonic::Geometry::FromEpsilonTensor->new(
    epsilon=>$epsilon);
my $wavenumber=pdl(.05);
my $wavevector=pdl(0,0,.02); # different from wavenumber
my $metric=Photonic::WE::ST::Metric->new(
    geometry=>$geometry, epsilon=>$epsilonRef, wavenumber=>$wavenumber, wavevector=>$wavevector
    );

#my $haydock=Photonic::WE::ST::Haydock->new(metric=>$metric, polarization=>$polarization, nh=>$nh);
my $greenObj=Photonic::WE::ST::Green->new(metric=>$metric, nh=>$nh);
my $green=$greenObj->greenTensor;
say $green;
my $epsM=$greenObj->epsilonTensor;
say $epsM;
