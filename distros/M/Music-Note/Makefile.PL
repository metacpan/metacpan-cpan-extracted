use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Music::Note',
    VERSION_FROM => 'lib/Music/Note.pm', # finds $VERSION
    AUTHOR       => 'Ben Daglish (bdaglish@cpan.org)',
    ABSTRACT     => 'Musical Note encapsulation/representation',
);
