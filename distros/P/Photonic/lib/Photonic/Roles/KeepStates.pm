=head1 NAME

Photonic::Roles::KeepStates

=head1 VERSION

version 0.009

=head1 SYNOPSIS

   package Photonic::MyPackage;
   use Moose;
   with 'Photonic::Roles::KeepStates;
   has 'myfield' => (is=>'ro');
   ...

=head1 DESCRIPTION

Fields that have been factored as they are common in different
Photonic subpackages to calculate the electromagnetic field

=head1 ACCESORS (read only)

=head2 keepStates

Flag to keep the states that make up a Haydock basis. Default: don't
keep states (0).  

=cut

package Photonic::Roles::KeepStates;
$Photonic::Roles::KeepStates::VERSION = '0.009';
use Moose::Role;



has 'keepStates'=>(is=>'ro', required=>1, default=>0,
         documentation=>'flag to save Haydock states');


no Moose::Role;

1;
