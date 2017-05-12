use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Personality::Type::MBTI',
    AUTHOR              => 'Nelson Ferraz <nferraz@gmail.com>',
    VERSION_FROM        => 'lib/Personality/Type/MBTI.pm',
    ABSTRACT_FROM       => 'lib/Personality/Type/MBTI.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Personality-Type-MBTI-*' },
);
