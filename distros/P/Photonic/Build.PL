# Build.PL
# Use to build the package Photonic
our $VERSION = '0.009';
    
use strict;
use warnings;
use PDL::Core::Dev;
use ExtUtils::F77 1.20;
use Module::Build::Pluggable ('PDL', 'Fortran');

my $builder = Module::Build::Pluggable->new(
    module_name=> 'Photonic',
    dist_name  => 'Photonic',
    dist_author=> [
	'W. Luis Mochan <mochan@fis.unam.mx>',
	'Guillermo Ortiz <gortiz@exa.unne.edu.ar>',
	'Bernardo S. Mendoza <bms@cio.mx>',
	'Jose Samuel Perez-Huerta <jsperez@fisica.uaz.edu.mx>'
	],
    dist_version_from => 'lib/Photonic.pm',
    license    => 'perl',
    release_status => 'stable', #stable, testing or unstable
    f_source   => [ 'fortran' ],
    requires   => { 
	"Inline" => 0,
	"List::Util" => 0,
	"Moose" => 0,
	"Moose::Role" => 0,
	"Moose::Util::TypeConstraints" => 0,
	"PDL" => 0,
	"PDL::FFTW3" => 0,
	"PDL::IO::Pic" => 0,
	"PDL::IO::Storable" => 0,
	"PDL::NiceSlice" => 0,
	"Storable" => 0,
	"Carp" => 0,
    },
    test_requires => {
	"Test::More" => 0,
	"Pod::Coverage::TrustPod" => 0,
	# "namespace::autoclean" => 0,
    },
    configure_requires => {
	'Module::Build'                      => '0.4004',
	'Module::Build::Pluggable'           => '0',
	'Module::Build::Pluggable::Fortran'  => '0.20',
	'Module::Build::Pluggable::PDL'      => '0.23',
	'ExtUtils::F77'                      => '1.20',
	'ExtUtils::CBuilder'                 => '0',
	'File::Copy'                         => '0',
    },
    add_to_cleanup  => [ 'Photonic-*', '.xs' ],
    create_makefile_pl => 'small',
    );
$builder->create_build_script();
