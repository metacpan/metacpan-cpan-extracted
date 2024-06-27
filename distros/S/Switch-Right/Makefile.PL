use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Switch::Right',
    AUTHOR              => 'Damian Conway <DCONWAY@CPAN.org>',
    VERSION_FROM        => 'lib/Switch/Right.pm',
    ABSTRACT_FROM       => 'lib/Switch/Right.pm',
    PL_FILES            => {},
    LICENSE             => 'artistic2',
    MIN_PERL_VERSION    => 5.036,
    PREREQ_PM => {
        'Test2::V0'       => 0,
        'Object::Pad'     => 0,   # for t/smartmatch_SMARTMATCH.t
        'B::Deparse'      => 0,
        'Keyword::Simple' => 0,
        'Multi::Dispatch' => 0,
        'PPR'             => 0.001009,
        'Type::Tiny'      => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Switch-Right-*' },
);
