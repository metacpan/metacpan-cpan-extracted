use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Music::Harmonics',
    AUTHOR              => 'Christian Renz <crenz@web42.com>',
    VERSION_FROM        => 'lib/Music/Harmonics.pm',
    ABSTRACT_FROM       => 'lib/Music/Harmonics.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'MIDI::Pitch' => 0.4,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Music-Harmonics-*' },
);
