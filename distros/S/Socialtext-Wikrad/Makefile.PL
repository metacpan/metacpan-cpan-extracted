use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Socialtext::Wikrad',
    AUTHOR              => 'Luke Closs <cpan@5thplane.com>',
    VERSION_FROM        => 'lib/Socialtext/Wikrad.pm',
    ABSTRACT_FROM       => 'lib/Socialtext/Wikrad.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Socialtext::Resting'         => '0.24',
        'Socialtext::EditPage'        => '0.04',
        'Socialtext::Resting::Getopt' => '0',
        'Curses::UI'                  => '0.95',
        'JSON'                        => '0',
    },
    EXE_FILES           => ['bin/wikrad'],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Socialtext-Wikrad-*' },
);
