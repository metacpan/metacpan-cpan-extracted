use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'POE::Component::NomadJukebox',
    'VERSION_FROM' => 'NomadJukebox.pm', # finds $VERSION
    'PREREQ_PM'	=> {
		'Test::More'	=> 0.32,
		'POE'			=> 0.22,
		'MP3::Tag'		=> undef,
    },
);
