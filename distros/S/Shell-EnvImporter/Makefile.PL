use 5.008003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Shell::EnvImporter',
    VERSION_FROM      => 'lib/Shell/EnvImporter.pm', # finds $VERSION
    PREREQ_PM         => {
        'Class::MethodMaker'    => 0,
    },
    ABSTRACT          => 'Perl extension for importing environment variable changes from external commands or shell scripts',
    AUTHOR            => 'David Faraldo <dfaraldo@cpan.org>',
);
