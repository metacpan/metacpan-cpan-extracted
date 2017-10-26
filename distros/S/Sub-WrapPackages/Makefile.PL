use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Sub::WrapPackages',
    META_MERGE => {
        license => 'other',
        resources => {
	    repository => 'https://github.com/DrHyde/perl-modules-Sub-WrapPackages',
	    bugtracker => 'https://github.com/DrHyde/perl-modules-Sub-WrapPackages/issues'
        }
    },
    VERSION_FROM => 'lib/Sub/WrapPackages.pm',
    PREREQ_PM    => {
        'Sub::Prototype' => 0.02,
        # 'Sub::Uplevel'   => 0.22,
        'Devel::Caller::IgnoreNamespaces' => 1.0,
    }
);
