use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Parallel::ForkControl',
    VERSION_FROM      => 'lib/Parallel/ForkControl.pm', # finds $VERSION
    PREREQ_PM         => { 
							'Storable'	=> 0,
							'POSIX'		=> 0,
							'CHI'		=> 0,
							'Try::Tiny'	=> 0,
						}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Parallel/ForkControl.pm', # retrieve abstract from module
       AUTHOR         => 'Brad Lhotsky <brad@divisionbyzero.net>') : ()),
);
