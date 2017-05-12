use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'RPC::Oracle',
    VERSION_FROM      => 'lib/RPC/Oracle.pm', # finds $VERSION
    PREREQ_PM         => { 
      DBI => '',
      'DBD::Oracle' => '',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/RPC/Oracle.pm', # retrieve abstract from module
       AUTHOR         => 'Warren Smith <wsmith@cpan.org>') : ()),
);
