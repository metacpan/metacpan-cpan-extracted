use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'PepXML::Parser',
    AUTHOR           => q{Felipe da Veiga Leprevost <leprevost@cpan.org>},
    VERSION_FROM     => 'lib/PepXML/Parser.pm',
    ABSTRACT_FROM    => 'README.pod',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
    "XML::Twig"             =>	3.49,
		"Moose"                 =>	0,
		"namespace::autoclean"	=>	0,
    },

    (! eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () :
        (META_ADD => {
    	    resources => {
        	    homepage   => 'https://github.com/Leprevost/PepXML-Parser',
                repository => 'https://github.com/Leprevost/PepXML-Parser.git',
                bugtracker => 'https://rt.cpan.org/NoAuth/Bugs.html?Dist=PepXML-Parser',
            },
        })
    ),

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PepXML-Parser-*' },
);
