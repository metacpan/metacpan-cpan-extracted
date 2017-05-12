use ExtUtils::MakeMaker;
use 5.006;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Parse::Stallion',
    VERSION_FROM      => 'lib/Parse/Stallion.pm', # finds $VERSION
    PREREQ_PM         => {'Test::More' => 0.71
     ,'Time::Local' => 0
     ,'Carp' => 0
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Parse/Stallion.pm', # retrieve abstract from module
       AUTHOR         => 'Arthur Goldstein <arthur@acm.org>') : ()),
);
