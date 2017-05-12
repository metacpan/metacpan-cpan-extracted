use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'POD2::FR',
    VERSION_FROM      => 'FR.pm', # finds $VERSION
    PREREQ_PM         => {Test::More}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'FR.pm', # retrieve abstract from module
       AUTHOR         => 'Paul GABORIT <gaborit@enstimac.fr>') : ()),
);
