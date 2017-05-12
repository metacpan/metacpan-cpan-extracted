use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Statistics::LineFit',
    VERSION_FROM => 'lib/Statistics/LineFit.pm', # finds $VERSION
    AUTHOR       => 'Richard Anderson (cpan(AT)richardanderson(DOT)org)',
    ABSTRACT     => '',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
