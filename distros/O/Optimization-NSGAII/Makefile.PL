use 5.006;;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Optimization::NSGAII',
    VERSION_FROM      => 'lib/Optimization/NSGAII.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Optimization/NSGAII.pm', # retrieve abstract from module
    AUTHOR            => 'dario <darvitdarvit@cpan.org>',
    LICENSE           => 'artistic_2',
);
