use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Sub::Prepend',
    VERSION_FROM => 'lib/Sub/Prepend.pm',
    AUTHOR       => 'Johan Lodin <lodin@cpan.org>',
    ABSTRACT     => 'Sub::Prepend',
    PREREQ_PM    => {
        Carp => 0,
        Symbol => 0,
        Scalar::Util => 1.11,

        # For testing:
        Test::More => 0.45,
        Test::Exception => 0.26,
    },
);
