use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME			=> 'RAS::AS5200',
	VERSION_FROM		=> 'AS5200.pm',
	PREREQ_PM		=> {
		Net::Telnet		=> 0,
	},
);
