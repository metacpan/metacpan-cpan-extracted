use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Sub::Throttle',
    VERSION_FROM   => 'lib/Sub/Throttle.pm',
    PREREQ_PM      => {
        List::Util  => 0,
        Time::HiRes => 0,
    },
    ABSTRACT_FROM => 'lib/Sub/Throttle.pm',
    AUTHOR        => 'Kazuho Oku',
);
