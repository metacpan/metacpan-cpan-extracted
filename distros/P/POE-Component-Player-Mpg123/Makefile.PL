use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	NAME			=> 'POE::Component::Player::Mpg123',
	VERSION_FROM	=> 'Mpg123.pm', 
	AUTHOR			=> 'Erick Calder <ecalder@cpan.org>',
	ABSTRACT_FROM	=> 'Mpg123.pm',
	PREREQ_PM		=> {
		POE::Component::Child => '1.16'
		},
	);
