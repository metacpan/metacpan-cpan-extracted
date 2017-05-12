use 5.008009;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'NoSQL::PL2SQL::Simple',
    VERSION_FROM      => 'lib/NoSQL/PL2SQL/Simple.pm', # finds $VERSION
    PREREQ_PM         => {
			NoSQL::PL2SQL => 1.21,
			}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/NoSQL/PL2SQL/Simple.pm', # retrieve abstract from module
       AUTHOR         => 'Jim Schueler <jim@tqis.com>') : ()),
);
