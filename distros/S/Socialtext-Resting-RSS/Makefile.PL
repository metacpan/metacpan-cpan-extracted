use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Socialtext::Resting::RSS',
    AUTHOR              => 'Luke Closs <cpan@5thplane.com>',
    VERSION_FROM        => 'lib/Socialtext/Resting/RSS.pm',
    ABSTRACT_FROM       => 'lib/Socialtext/Resting/RSS.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Socialtext::Resting'        => '0.22',
        'Socialtext::Resting::Utils' => '0.17',
        'Test::More'                 => 0,
        'JSON'                       => 0,
        'YAML'                       => 0,
        'XML::RSS'                   => 0,
        'Text::Diff'                 => 0,
    },
    EXE_FILES           => [
        'bin/st-rss', 
    ],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Socialtext-Resting-RSS-*' },
);
