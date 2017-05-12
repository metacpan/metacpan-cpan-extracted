use ExtUtils::MakeMaker;
WriteMakefile(
	NAME         => 'Sailthru::Client',
	VERSION_FROM => 'lib/Sailthru/Client.pm',
	PREREQ_PM    => {
		Digest::MD5          => 0,
		JSON::XS             => 0,
		LWP::Protocol::https => 0,
		LWP::UserAgent       => 0,
		Params::Validate     => 0,
		Readonly             => 0,
		URI                  => 0,
		Test::MockModule     => 0,
		Test::Exception      => 0,
	},
	ABSTRACT_FROM => 'lib/Sailthru/Client.pm',
	AUTHOR        => 'Sam Gerstenzang <sgerstenzang@stanford.edu>, Steve Miketa <steve@sailthru.com>, Steve Sanbeg <stevesanbeg@buzzfeed.com>, Finn Smith <finn@timeghost.net>'
);
