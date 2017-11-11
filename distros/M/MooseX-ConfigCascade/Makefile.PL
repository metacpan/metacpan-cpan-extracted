use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'MooseX::ConfigCascade',
    VERSION_FROM      => 'lib/MooseX/ConfigCascade.pm',
    PREREQ_PM         => {
        "Moose" => 0,
        "MooseX::ClassAttribute" => 0,
        "Carp" => 0,
        "Module::Runtime" => 0,
        "Moose::Role" => 0,
	"YAML" => 0,
	"JSON" => 0
    },
    TEST_REQUIRES     => {
        'Test::More'  => 0,
        'File::Spec'  => 0,
        'Cwd'         => 0,
        'Try::Tiny'   => 0,
        'Carp'        => 0
    },
    ABSTRACT_FROM     => 'lib/MooseX/ConfigCascade.pm',
    AUTHOR            => 'Tom Gracey <tomgracey@gmail.com>',
    LICENSE           => 'perl'
);
