use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Pod::Term',
    VERSION_FROM      => 'lib/Pod/Term.pm',
    PREREQ_PM         => {
        "Pod::Simple" => 0,
        "Term::ANSIColor" => 0,
        "Carp" => 0,
        "Clone" => 0,
        "Hash::Merge" => 0,
    },
    TEST_REQUIRES     => {
        'Test::More'  => 0,
        'Pod::Simple'  => 0
    },
    ABSTRACT_FROM     => 'lib/Pod/Term.pm',
    AUTHOR            => 'Tom Gracey <tomgracey@gmail.com>',
    LICENSE           => 'perl'
);
