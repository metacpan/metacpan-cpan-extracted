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
	'Raksha Singla  <raksharuia@gmail.com>',
	'Merlyn Jaqueline Juarez-Gutierrez <merlynj@icf.unam.mx>',
	],
    ABSTRACT=> 'A perl package for calculations on photonics and metamaterials.',
    VERSION_FROM => 'lib/Photonic.pm',
    LICENSE    => 'perl',
    MIN_PERL_VERSION => '5.16.0',                 # so PDL::FFTW3 also installs
    PREREQ_PM => {
	'Carp'                           => '0',
	'IO::File'                       => '0',
	'List::Util'                     => '0',
	'Machine::Epsilon'               => '0',
	'Moo'                            => '0',
	'namespace::autoclean'           => '0',
	'Type::Tiny'                     => '0',
	'MooX::StrictConstructor'        => '0',
	'PDL'                            => '2.093', # PDL::Complex->from_native, inner for complex
	'PDL::Constants'                 => '0',
	'PDL::Core'                      => '0',
	'PDL::Core::Dev'                 => '0',
	'PDL::IO::Pic'                   => '0',
	'PDL::IO::Storable'              => '0',
	'PDL::IO::FastRaw'               => '0',
	'PDL::Lite'                      => '0',
	'PDL::MatrixOps'                 => '0',
	'PDL::NiceSlice'                 => '0',
	'PDL::FFTW3'                     => '0.15', # fix ifftn bug
	'PDL::LinearAlgebra'             => '0.20', # native-complex fixes
	'Storable'                       => '0',
    },
    TEST_REQUIRES => {
        'Machine::Epsilon'            => '0',
	'Test::More'                  => '0.88',
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
                    'Test::Pod' => '1.22',
                    'Test::Pod::Coverage' => '1.08',
                    'Test::Version' => '1.003001',
                },
            },
        },
    },
);
