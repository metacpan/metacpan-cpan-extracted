use 5.012003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Sorauta::SVN::AutoCommit',
    VERSION_FROM      => 'lib/Sorauta/SVN/AutoCommit.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Sorauta/SVN/AutoCommit.pm', # retrieve abstract from module
       AUTHOR         => 'Yuki ANAI <yuki@apple.com>') : ()),
);
