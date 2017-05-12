use ExtUtils::MakeMaker;

WriteMakefile
(
    NAME            => 'Signal::StackTrace',
    VERSION_FROM    => './lib/Signal/StackTrace.pm',
    ABSTRACT_FROM   => './lib/Signal/StackTrace.pm',
    PREREQ_PM =>
    {
        # standard distro, particular versions 
        # are unlikely to cause pain.

        blib            => 0,
        strict          => 0,
        Carp            => 0,
        Config          => 0,
        Data::Dumper    => 0,
    },
);

