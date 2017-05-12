use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Pulp',
    VERSION_FROM    => 'lib/Pulp.pm',
    ABSTRACT        => 'Give your Kelp applications extra juice',
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' },
    DISTNAME        => 'Pulp',
    EXE_FILES       => [ 'bin/pulp' ],
    TEST_REQUIRES   => {
        'Test::More' => 0,
        'Kelp::Test' => 0,
        'Kelp::Module::Template::Toolkit' => 0,
        'DBIx::Class' => 0,
    },

    PREREQ_PM       => {
        'Moo'       => 0,
        'Kelp'      => 0,
        'true'      => 0,
        'Text::ASCIITable' => 0,
        'Module::Find' => 0,
    },        
);
