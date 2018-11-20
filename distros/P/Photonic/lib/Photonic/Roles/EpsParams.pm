=head1 NAME

Photonic::Roles::EpsParams

=head1 VERSION

version 0.010

=head1 SYNOPSIS

   package Photonic::MyPackage;
   use Moose;
   with 'Photonic::Roles::EpsParams;
   has 'myfield' => (is=>'ro');
   ...

=head1 DESCRIPTION

Fields that have been factored as they are common in different
Photonic subpackages to calculate the macroscopic dielectric function

=head1 ACCESORS (read only)

=head2 nh
   
Desired no. of Haydock coefficients

=head2 smallH

Convergence criterium for Haydock coefficient calculations. Default is 1e-7.

=head2 smallE

Convergence criterium for Haydock coefficient use. Default is 1e-7.

=head2 epsA

Dielectric function of host

=head2 epsB

Dielectric function of inclusions

=head2 u

Spectral variable

=cut





package Photonic::Roles::EpsParams;
$Photonic::Roles::EpsParams::VERSION = '0.010';
use Moose::Role;

has 'nh' =>(is=>'ro', isa=>'Num', required=>1, 
	    documentation=>'Desired no. of Haydock coefficients');
has 'smallH'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for Haydock coefficients');
has 'smallE'=>(is=>'ro', isa=>'Num', required=>1, default=>1e-7,
    	    documentation=>'Convergence criterium for use of Haydock coeff.');
has 'epsA'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef, writer=>'_epsA',
    documentation=>'Dielectric function of host');
has 'epsB'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef, writer=>'_epsB',
        documentation=>'Dielectric function of inclusions');
has 'u'=>(is=>'ro', isa=>'PDL::Complex', init_arg=>undef, writer=>'_u',
    documentation=>'Spectral variable');

no Moose::Role;

1;
