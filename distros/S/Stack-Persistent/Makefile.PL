use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Stack::Persistent',
    VERSION_FROM      => 'lib/Stack/Persistent.pm', # finds $VERSION
    PREREQ_PM         => {Cache::FastMmap => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Stack/Persistent.pm', # retrieve abstract from module
       AUTHOR         => 'Kevin L. Esteb <kesteb@wsipc.org>') : ()),
);
