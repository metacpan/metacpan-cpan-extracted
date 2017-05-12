use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'ObjectDBI',
    VERSION_FROM      => 'lib/ObjectDBI.pm', # finds $VERSION
    PREREQ_PM         => { DBI => 1.3 }, # e.g., Module::Name => 1.1
    BUILD_REQUIRES    => { 'DBD::CSV' => 0 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/ObjectDBI.pm', # retrieve abstract from module
       AUTHOR         => 'Kees Jan Hermans <kees@pink-frog.com>') : ()),
);
