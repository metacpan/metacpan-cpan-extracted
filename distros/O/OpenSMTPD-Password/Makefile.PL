use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	NAME	=> 'OpenSMTPD::Password',
	VERSION_FROM	=> 'lib/OpenSMTPD/Password.pm',
	PREREQ_PM	=> { BSD::arc4random => 1.50 },
	ABSTRACT_FROM	=> 'lib/OpenSMTPD/Password.pm',
	AUTHOR		=> 'Edgar Pettijohn <edgar@pettijohn-web.com>',
	LICENSE		=> 'open_source',
);
