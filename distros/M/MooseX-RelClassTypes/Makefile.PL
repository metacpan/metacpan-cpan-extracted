use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'MooseX::RelClassTypes',
    VERSION_FROM      => 'lib/MooseX/RelClassTypes.pm',
    PREREQ_PM         => {
        "Moose" => 0,
        "MooseX::Role::Parameterized" => 0,
        "Module::Runtime" => 0,
        "Carp" => 0,
        "Clone" => 0
    }, 
    TEST_REQUIRES => {
        "Test::More" => 0
    },
    ABSTRACT_FROM     => 'lib/MooseX/RelClassTypes.pm', # retrieve abstract from module
    AUTHOR            => 'Tom Gracey <tomgracey@gmail.com>',
    LICENSE           => 'perl'
);
