use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Sub::Curry',
    VERSION_FROM => 'lib/Sub/Curry.pm', # finds $VERSION
    AUTHOR       => 'Johan Lodin <lodin@cpan.org>',
    ABSTRACT     => 'Sub::Curry',
    PREREQ_PM    => {
        Test::More => 0.45,
    },
);
