use 5.014002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Test::Bitcoin::Daemon',
    VERSION_FROM      => 'lib/Test/Bitcoin/Daemon.pm', # finds $VERSION
    PREREQ_PM         => {
      'File::Which'   => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Test/Bitcoin/Daemon.pm', # retrieve abstract from module
       AUTHOR         => 'Jean-Pierre Rupp <root@xeno-genesis.com>') : ()),
);
