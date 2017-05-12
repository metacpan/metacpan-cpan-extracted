use ExtUtils::MakeMaker;
eval { require Mite::MakeMaker };

WriteMakefile(
    NAME                => 'Some::Project',
    VERSION_FROM        => 'lib/Some/Project.pm',
);
