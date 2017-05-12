use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'SWISH::API::Object',
    VERSION_FROM => 'lib/SWISH/API/Object.pm',    # finds $VERSION
    PREREQ_PM    => {

        'SWISH::API::Stat' => '0.03',
        'YAML::Syck'       => '0.72',
        'Data::Dump'       => 0,

    },                                            # e.g., Module::Name => 1.1
    (   $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
            (
            ABSTRACT_FROM =>
                'lib/SWISH/API/Object.pm',    # retrieve abstract from module
            AUTHOR => 'Peter Karman <karman@cpan.org>'
            )
        : ()
    ),

    clean => { FILES => 't/index.swish-e t/index.swish-e.prop' }
);
