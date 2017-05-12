use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	NAME			=> 'POE::Component::Enc::Mp3',
	VERSION_FROM	=> 'Mp3.pm', 
	AUTHOR			=> 'Erick Calder <ecalder@cpan.org>',
	ABSTRACT_FROM	=> 'Mp3.pm',
	PREREQ_PM		=> { POE => '0.22' },
	);
