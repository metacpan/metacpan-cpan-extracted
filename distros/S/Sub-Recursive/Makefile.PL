use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Sub::Recursive',
    VERSION_FROM => 'lib/Sub/Recursive.pm',
    AUTHOR       => 'Johan Lodin <lodin@cpan.org>',
    ABSTRACT     => 'Sub::Recursive',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        Test::More => 0.45,
    },
);
