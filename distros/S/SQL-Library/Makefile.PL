use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'SQL::Library',
    VERSION_FROM => 'lib/SQL/Library.pm', # finds $VERSION
    AUTHOR       => 'Doug Gorley (dgorley@cpan.org)',
    ABSTRACT     => 'SQL::Library',
    PREREQ_PM    => {
                     'Test::More' => 0.47,
                    },
);
