use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Pod::Simple::LaTeX',
    VERSION_FROM => 'lib/Pod/Simple/LaTeX.pm',
    PREREQ_PM    => { Pod::Simple => 0.01 },
);
