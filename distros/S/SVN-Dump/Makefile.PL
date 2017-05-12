use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'SVN::Dump',
    VERSION_FROM => 'lib/SVN/Dump.pm',
    PREREQ_PM    => {
        'Test::More'     => 0,
    },
    PL_FILES => {},
    ABSTRACT_FROM => 'lib/SVN/Dump.pm',
    AUTHOR        => 'Philippe "BooK" Bruhat <book@cpan.org>',
    META_MERGE => {
        resources => {
            repository => 'http://github.com/book/SVN-Dump',
        },
    },
    LICENSE             => 'perl',
);
