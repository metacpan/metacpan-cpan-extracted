use 5.006; # need lexical warnings
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Palm::Treo680MessagesDB',
    META_MERGE => {
        license => 'other',
        resources => {
            repository => 'https://github.com/DrHyde/perl-modules-Palm-Treo680MessagesDB',
            bugtracker => 'https://github.com/DrHyde/perl-modules-Palm-Treo680MessagesDB/issues'
        }
    },
    VERSION_FROM => 'lib/Palm/Treo680MessagesDB.pm',
    PREREQ_PM    => {
        Palm::PDB       => 1.016,
        DateTime        => 0.30,
        Data::Hexdumper => 0,
        Test::More      => 0
    },
    EXE_FILES => [qw(
        examples/treo680smsdump
    )]
);
