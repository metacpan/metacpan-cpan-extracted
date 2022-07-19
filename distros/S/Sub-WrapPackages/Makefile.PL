use ExtUtils::MakeMaker;
WriteMakefile(
    NAME       => 'Sub::WrapPackages',
    META_MERGE => {
        license   => 'open_source',
        resources => {
            repository => 'https://github.com/DrHyde/perl-modules-Sub-WrapPackages',
            bugtracker => 'https://github.com/DrHyde/perl-modules-Sub-WrapPackages/issues'
        }
    },
    VERSION_FROM => 'lib/Sub/WrapPackages.pm',
    PREREQ_PM    => {
        Capture::Tiny                   => 0,
        Devel::Caller::IgnoreNamespaces => 1.0,
        Sub::Prototype                  => 0.02,
        Test::More                      => 0.88, # done_testing
    }
);
