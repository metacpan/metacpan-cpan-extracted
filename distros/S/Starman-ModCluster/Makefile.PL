use 5.008_001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Starman::ModCluster',
    VERSION_FROM      => 'lib/Starman/ModCluster.pm', # finds $VERSION
    EXE_FILES		  => ['bin/starman-modcluster'],
    PREREQ_PM         => {
    	'Net::MCMP' => 0,
 		'Starman'	=> 0,
 		'IO::Socket::Multicast' => 0,
 		'IPC::Shareable' => 0,
 #		'Config::General' => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.008 ?     ## Add these new keywords supported since 5.008
      (ABSTRACT_FROM  => 'lib/Starman/ModCluster.pm', # retrieve abstract from module
       AUTHOR         => 'Roman Jurkov <winfinit@cpan.org>') : ()),
);
