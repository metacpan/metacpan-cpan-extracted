use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Term::Highlight',
    AUTHOR          => 'A. Radkov <alexey.radkov@gmail.com>',
    VERSION_FROM    => 'hl',
    ABSTRACT_FROM   => 'Highlight.pm',
    LICENSE         => 'perl_5',
    EXE_FILES       => [ 'hl' ]
);
