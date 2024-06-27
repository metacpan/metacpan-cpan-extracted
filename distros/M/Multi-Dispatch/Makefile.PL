use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Multi::Dispatch',
    AUTHOR              => 'Damian Conway <DCONWAY@CPAN.org>',
    VERSION_FROM        => 'lib/Multi/Dispatch.pm',
    ABSTRACT_FROM       => 'lib/Multi/Dispatch.pm',
    PL_FILES            => {},
    LICENSE             => 'artistic2',
    MIN_PERL_VERSION    => 5.022,
    PREREQ_PM => {
        'Test::More'             => 0,
        'Data::Dump'             => 0,
        'Keyword::Simple'        => 0.04,
        'PPR'                    => 0.001004,
        'Algorithm::FastPermute' => 0,
        'Type::Tiny'             => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'multi-*' },
);
