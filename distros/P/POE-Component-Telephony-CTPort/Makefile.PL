use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME' => 'POE::Component::Telephony::CTPort',
    'VERSION_FROM' => 'CTPort.pm',
    'PREREQ_PM' => {
		'Test::More'					=> 0.32,
		'POE'							=> 0.22,
		'IO::Pty'						=> undef,
		'File::Basename'				=> undef,
		'POE::Wheel::Run'				=> undef,
		'POE::Component::Client::TCP'	=> undef,
    },
);
