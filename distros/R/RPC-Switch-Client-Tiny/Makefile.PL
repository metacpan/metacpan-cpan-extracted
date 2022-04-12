use strict;
use warnings;

use 5.016;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'RPC::Switch::Client::Tiny',
	AUTHOR           => 'Barnim Dzwillo @ Strato AG',
	VERSION_FROM     => 'lib/RPC/Switch/Client/Tiny.pm',
	ABSTRACT_FROM    => 'lib/RPC/Switch/Client/Tiny.pm',
	MIN_PERL_VERSION => "5.016",
	PREREQ_PM => {
		'JSON' => 1,
		'IO::Socket::SSL' => 1,
	},
);
