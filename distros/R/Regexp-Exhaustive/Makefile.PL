use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Regexp::Exhaustive',
    VERSION_FROM => 'lib/Regexp/Exhaustive.pm',
    AUTHOR       => 'Johan Lodin <lodin@cpan.org>',
    ABSTRACT     => 'Regexp::Exhaustive',
    PREREQ_PM    => {
        Scalar::Util => 0,
        Test::More => 0.45,
    },
);
