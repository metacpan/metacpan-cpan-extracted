use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::MSN::PassPort',
    'VERSION_FROM'	=> 'PassPort.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	LWP::UserAgent => 2.013
    }, # e.g., Module::Name => 1.1
);
