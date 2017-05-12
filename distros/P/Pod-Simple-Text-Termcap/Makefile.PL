use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Pod::Simple::Text::Termcap',
    AUTHOR              => 'Boris Zentner <bzm@2bz.de>',
    VERSION_FROM        => 'lib/Pod/Simple/Text/Termcap.pm',
    ABSTRACT_FROM       => 'lib/Pod/Simple/Text/Termcap.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Pod::Simple' => 3,
        'Term::Cap'   => 0,
        'Test::More'  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Pod-Simple-Text-Termcap-*' },
);
