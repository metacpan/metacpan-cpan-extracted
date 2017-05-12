use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Sort::MultipleFields',
    META_MERGE => {
        license => 'other',
        resources => {
            repository => 'https://github.com/DrHyde/perl-modules-Sort-MultipleFields',
            bugtracker => 'https://github.com/DrHyde/perl-modules-Sort-MultipleFields/issues'
        }
    },
    VERSION_FROM => 'lib/Sort/MultipleFields.pm',
    PREREQ_PM    => {
        Test::More      => 0,
        Scalar::Util    => 0,
        # Exporter      => 0,   # in core since beginning of time
    },
);
