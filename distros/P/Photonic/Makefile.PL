use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME=> 'Photonic',
    AUTHOR=> [
	'W. Luis Mochan <mochan@fis.unam.mx>',
	'Guillermo Ortiz <gortiz@exa.unne.edu.ar>',
	'Bernardo S. Mendoza <bms@cio.mx>',
	'Jose Samuel Perez-Huerta <jsperez@fisica.uaz.edu.mx>',
	'Lucila Juarez Reyes <lucilajuarezreyes@gmail.com>',
	'Merlyn Jaqueline Juarez-Gutierrez <merlynj@icf.unam.mx>'
	],
    VERSION_FROM => 'lib/Photonic.pm',
    LICENSE    => 'perl',
    MIN_PERL_VERSION => '5.14.0',
    PREREQ_PM => {
	'Carp'                           => '0',
	'ExtUtils::F77'                  => '1.23',
	'IO::File'                       => '0',
	'List::Util'                     => '0',
	'Machine::Epsilon'               => '0',
	'Moose'                          => '0',
	'Moose::Role'                    => '0',
	'Moose::Util::TypeConstraints'   => '0',
	'MooseX::StrictConstructor'      => '0',
	'PDL'                            => '0',
	'PDL::Complex'                   => '2.009',
	'PDL::Constants'                 => '0',
	'PDL::Core'                      => '0',
	'PDL::Core::Dev'                 => '0',
	'PDL::Exporter'                  => '0',
	'PDL::FFTW3'                     => '0',
	'PDL::IO::Pic'                   => '0',
	'PDL::IO::Storable'              => '0',
	'PDL::Lite'                      => '0',
	'PDL::MatrixOps'                 => '0',
	'PDL::NiceSlice'                 => '0',
	'PDL::FFTW3'                     => '0',
	'PDL::LinearAlgebra'             => '0.15', # cgtsv
	'Storable'                       => '0',
    },
    TEST_REQUIRES => {
	'Machine::Epsilon'            => '0',
	'Test::More'                  => '0',
    },
    CONFIGURE_REQUIRES => {
	'ExtUtils::MakeMaker' => '0',
    },
    META_MERGE     => {
        "meta-spec" => { version => 2 },
        dynamic_config => 0,
        resources => {
            repository => {
                type => 'git',
                url => 'git@github.com:wlmb/Photonic.git',
                web => 'https://github.com/wlmb/Photonic',
            },
        },
        prereqs => {
            develop => {
                requires => {
                    'Test::CheckManifest' => '0.9',
                    'Pod::Coverage::TrustPod' => '0',
                    'Test::Pod' => '1.22',
                    'Test::Pod::Coverage' => '1.08',
                    'Test::Version' => '1.003001',
                },
            },
        },
    },
);
