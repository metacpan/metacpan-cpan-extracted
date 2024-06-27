use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Switch::Back',
    AUTHOR              => 'Damian Conway <DCONWAY@CPAN.org>',
    VERSION_FROM        => 'lib/Switch/Back.pm',
    ABSTRACT_FROM       => 'lib/Switch/Back.pm',
    PL_FILES            => {},
    LICENSE             => 'artistic2',
    MIN_PERL_VERSION    => 5.036,
    PREREQ_PM => {
        'Test::More'      => 0,
        'Keyword::Simple' => 0,
        'Multi::Dispatch' => 0,
        'PPR'             => 0.001009,
        'Type::Tiny'      => 0,
        'B::Deparse'      => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Switch-Back-*' },
);
