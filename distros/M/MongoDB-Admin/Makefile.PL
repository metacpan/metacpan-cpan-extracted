use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MongoDB::Admin',
    VERSION_FROM      => 'lib/MongoDB/Admin.pm', # finds $VERSION
    PREREQ_PM         => { 'MongoDB' => '0.32'}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/MongoDB/Admin.pm', # retrieve abstract from module
       AUTHOR         => 'David Burley <david@geek.net>') : ()),
);
