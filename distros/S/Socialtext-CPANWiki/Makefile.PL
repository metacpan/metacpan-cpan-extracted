use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Socialtext::CPANWiki',
    AUTHOR              => 'Luke Closs <cpan@5thplane.com>',
    VERSION_FROM        => 'lib/Socialtext/CPANWiki.pm',
    ABSTRACT_FROM       => 'lib/Socialtext/CPANWiki.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Socialtext::Resting'         => '0.19',
        'Socialtext::Resting::Getopt' => '0',
        'XML::Liberal'                => '0',
        'LWP::Simple'                 => '0',
    },
    EXE_FILES           => ['bin/cpanwiki_update'],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Socialtext-CPANWiki-*' },
);
