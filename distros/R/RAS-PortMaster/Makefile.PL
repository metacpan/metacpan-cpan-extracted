use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME			=> 'RAS::PortMaster',
	VERSION_FROM		=> 'PortMaster.pm',
	PREREQ_PM		=> {
		Net::Telnet		=> 0,
	},
);
