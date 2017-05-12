use 5.000000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    EXE_FILES         => [ 'noid' ],
    NAME              => 'Noid',
    #VERSION_FROM      => 'lib/Noid.pm',    # finds $VERSION
    VERSION_FROM      => 'VERSION',    # finds $VERSION
    #VERSION           => '0.424',
    PREREQ_PM         => {
	#'BerkeleyDB'		=> '0.20', # and sleepycat BDB C lib > 2.7.7
	'BerkeleyDB'		=> '0', # 0.20; and sleepycat BDB C lib > 2.7.7
	'Fcntl'			=> '0',
	'Config'		=> '0',
	'Getopt::Long'		=> '0',
	'Sys::Hostname'		=> '0',
	'Text::ParseWords'	=> '0',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Noid.pm', # retrieve abstract from module
       AUTHOR         => 'John Kunze <jak@ucop.edu>') : ()),
);
