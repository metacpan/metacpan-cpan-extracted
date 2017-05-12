use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Template::Plugin::SafeInclude',
    VERSION_FROM        => 'lib/Template/Plugin/SafeInclude.pm',
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
        'parent'    => 0,
    },
);
