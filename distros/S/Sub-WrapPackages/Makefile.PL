use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Sub::WrapPackages',
    VERSION_FROM => 'lib/Sub/WrapPackages.pm',
    PREREQ_PM    => {
        'Sub::Prototype' => 0.02,
        # 'Sub::Uplevel'   => 0.22,
        'Devel::Caller::IgnoreNamespaces' => 1.0,
    }
);
