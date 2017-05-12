use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
	NAME => 'POE::Component::Client::Asterisk::Manager',
	VERSION_FROM => 'Manager.pm',
	'dist' => {
			'SUFFIX'       => ".gz",
			'DIST_DEFAULT' => 'all tardist',
			'COMPRESS'     => "gzip -9vf",
	},
	PREREQ_PM => {
		'POE::Component::Client::TCP'   => undef,
		'Digest::MD5'                   => 2.20,
		'POE'                           => 0.12_03,
	},
	'dist' => {
		'SUFFIX'       => '.gz',
		'DIST_DEFAULT' => 'all tardist',
		'COMPRESS'     => 'gzip -9vf',
	},
);
