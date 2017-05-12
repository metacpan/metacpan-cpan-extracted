use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Prolog::Utility::FromPerl',
    AUTHOR              => 'Tyson Maly <tvmaly@cpan.org>',
    VERSION_FROM        => 'lib/Prolog/Utility/FromPerl.pm',
    ABSTRACT_FROM       => 'lib/Prolog/Utility/FromPerl.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'Regexp::Common' => 0,
    },
    PREREQ_FATAL => 1,
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Prolog-Utility-FromPerl-*' },
);
