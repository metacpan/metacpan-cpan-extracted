use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Socialtext::MailArchive',
    AUTHOR              => 'Luke Closs <luke.closs@socialtext.com>',
    VERSION_FROM        => 'lib/Socialtext/MailArchive.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Socialtext::Resting'        => '0.15',
        'Socialtext::Resting::Utils' => '0.12',
        'Test::More'                 => 0,
    },
    EXE_FILES           => ['bin/st-archive-mail'],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Socialtext-MailArchive-*' },
);
