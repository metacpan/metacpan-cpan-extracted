use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME		=> 'PBS::Logs',
    VERSION_FROM	=> 'lib/PBS/Logs.pm', # finds $VERSION
    LICENSE		=> 'lgpl',
    PREREQ_PM		=> {
	Carp			=> 0,
	Time::Local		=> 0,		
			}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM	=> 'lib/PBS/Logs.pm', # retrieve abstract from module
       AUTHOR		=> 'Dr R K Owen <rkowen@nersc.gov>') : ()),
);
