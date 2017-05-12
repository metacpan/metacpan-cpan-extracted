use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'Module::Install::TestTarget',
    VERSION_FROM => 'lib/Module/Install/TestTarget.pm',
    ABSTRACT => 'Assembles test targets for `make` with code snippets',
    PREREQ_PM => {
        'Module::Install' => '1.00',
        'Test::More' => '0.96',
        'Test::Requires' => '0',
    },
    test => {
        TESTS => 't/*.t t/*/*.t',
    },
    LICENSE => 'perl',
);
