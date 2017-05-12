use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'MzML::Parser',
    AUTHOR           => q{Felipe da Veiga Leprevost <leprevost@cpan.org>},
    VERSION_FROM     => 'lib/MzML/Parser.pm',
    ABSTRACT_FROM    => 'README.pod',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
	'Moose'			        => 0,
	'namespace::autoclean' 	=> 0,
	'XML::Twig'	        	=> 0,
	'URI'       			=> 0,
    },
    (! eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () :
        (META_ADD => {
    	    resources => {
                homepage   => 'https://github.com/Leprevost/MzML-Parser',
                repository => 'https://github.com/Leprevost/MzML-Parser.git',
                bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=MzML-Parser',
            },
        })
    ),
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'MzML-Parser-*' },
);
