use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	NAME		=> 'POE::Component::Player::Musicus',
	VERSION_FROM	=> 'lib/POE/Component/Player/Musicus.pm',
	PREREQ_PM	=> {
		POE::Component::Child => '1.39',
		Text::Balanced => '0',
	},
	ABSTRACT_FROM	=> 'lib/POE/Component/Player/Musicus.pm',
	AUTHOR		=> 'Curtis Hawthorne <mrperson@cpan.org>',
);

