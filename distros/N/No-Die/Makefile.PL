use ExtUtils::MakeMaker;
use strict;

WriteMakefile (
    NAME            => 'No::Die',
    VERSION_FROM    => 'lib/No/Die.pm', # finds $VERSION
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    PREREQ_PM       => {    'Test::More'                => 0, 
                            'Locale::Maketext::Simple'  => 0,
                            'Params::Check'             => 0,     
                    },
    AUTHOR          => 'Jos Boumans <kane[at]cpan.org>',
	ABSTRACT        => q[Only let modules die when you say it's OK],
);   
