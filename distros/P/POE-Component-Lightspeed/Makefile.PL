use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME			=> 'POE::Component::Lightspeed',
	VERSION_FROM		=> 'lib/POE/Component/Lightspeed.pm', # finds $VERSION
	PREREQ_PM		=> {
		'POE'		=>	'0.31',
		'Graph'		=>	'0.60',
		'Carp'		=>	0,
		'Time::HiRes'	=>	0,
		'Socket'	=>	0,
	},
	($] >= 5.005 ?     ## Add these new keywords supported since 5.005
		(ABSTRACT_FROM  => 'lib/POE/Component/Lightspeed.pm', # retrieve abstract from module
		AUTHOR         => 'Apocalypse <APOCAL@cpan.org>') : ()),
);
