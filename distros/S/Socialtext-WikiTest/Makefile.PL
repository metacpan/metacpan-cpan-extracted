use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Socialtext::WikiTest',
    AUTHOR              => 'Luke Closs <cpan@5thplane.com>',
    VERSION_FROM        => 'lib/Socialtext/WikiTest.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Socialtext::Resting'        => 0,
        'Socialtext::Resting::Utils' => 0.04,
        'Test::More'                 => 0,
        'Test::Exception'            => 0,
        'mocked'                     => 0,
        },
    EXE_FILES           => [],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Socialtext-WikiTest-*' },
);
