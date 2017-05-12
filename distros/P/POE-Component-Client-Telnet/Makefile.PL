use warnings;
use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'POE::Component::Client::Telnet',
	AUTHOR        => 'David Davis <xantus@cpan.org>',
	ABSTRACT      => 'Non-blocking POE interface to Net::Telnet',
	VERSION_FROM  => 'lib/POE/Component/Client/Telnet.pm', # finds $VERSION
	PREREQ_PM     => {
		'Test::More'            => 0.32,
		'POE'                   => 0.31,
		'Net::Telnet'           => undef,
		'Devel::Symdump'		=> undef,
		'Carp'					=> undef,
	},
	dist        => {
		COMPRESS  => 'gzip -9f',
		SUFFIX    => 'gz',
	},
);
