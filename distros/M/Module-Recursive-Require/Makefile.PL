use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Module::Recursive::Require',
    VERSION_FROM => 'lib/Module/Recursive/Require.pm',
    PREREQ_PM    => {
        File::Spec         => 0,
        UNIVERSAL::require => 0,
    },
);
