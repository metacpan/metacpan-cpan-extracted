use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	NAME			=> 'POE::Component::CD::Rip',
	VERSION_FROM	=> 'Rip.pm', 
	AUTHOR			=> 'Erick Calder <ecalder@cpan.org>',
	ABSTRACT_FROM	=> 'Rip.pm',
	PREREQ_PM		=> { POE => '0.22' },
	);
