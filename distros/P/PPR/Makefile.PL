use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'PPR',
    AUTHOR              => 'Damian Conway <DCONWAY@CPAN.org>',
    VERSION_FROM        => 'lib/PPR.pm',
    ABSTRACT_FROM       => 'lib/PPR.pm',
    PL_FILES            => {},
    LICENSE             => 'artistic2',
    MIN_PERL_VERSION    => 5.010,
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'PPR-*' },
);
