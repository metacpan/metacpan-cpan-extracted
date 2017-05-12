use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Music::Gestalt',
    AUTHOR              => 'Christian Renz <crenz@web42.com>',
    VERSION_FROM        => 'lib/Music/Gestalt.pm',
    ABSTRACT_FROM       => 'lib/Music/Gestalt.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'MIDI' => 0,
        'MIDI::Pitch' => '0.6',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Music-Gestalt-*' },
);
