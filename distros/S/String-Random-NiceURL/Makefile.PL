use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'String::Random::NiceURL',
    AUTHOR              => 'Andrew Chilton <andy@chilts.org>',
    VERSION_FROM        => 'lib/String/Random/NiceURL.pm',
    ABSTRACT_FROM       => 'lib/String/Random/NiceURL.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Exception' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'String-Random-NiceURL-*' },
);
