use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Proc::ParallelLoop',
    VERSION_FROM => 'lib/Proc/ParallelLoop.pm', # finds $VERSION
    AUTHOR       => 'Byron C. Darrah (bdarrah@pacbell.net)',
    ABSTRACT     => 'Parallel looping constructs for Perl programs'
);
