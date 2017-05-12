use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	NAME			=> 'POE::Component::Player::Slideshow',
	VERSION_FROM	=> 'Slideshow.pm', 
	AUTHOR			=> 'Erick Calder <ecalder@cpan.org>',
	ABSTRACT_FROM	=> 'Slideshow.pm',
	PREREQ_PM		=> {
		POE::Component::Child => '1.22',
		X11::SendEvent => '1.4',
		},
	);
