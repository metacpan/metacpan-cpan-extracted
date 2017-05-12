use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::MSN::Debug',
    'VERSION_FROM'	=> 'Debug.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	Fcntl => 1.04,
	POSIX => 1.05
    }, # e.g., Module::Name => 1.1
);
