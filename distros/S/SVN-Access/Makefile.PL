use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SVN::Access',
    VERSION_FROM      => 'lib/SVN/Access.pm', # finds $VERSION
    PREREQ_PM         => {Tie::IxHash => 1.21}, # e.g., Module::Name => 1.1
    INST_SCRIPT       => 'bin',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SVN/Access.pm', # retrieve abstract from module
       AUTHOR         => 'Michael Gregorowicz <mike@mg2.org>') : ()),
);
