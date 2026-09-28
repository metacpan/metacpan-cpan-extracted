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
	LICENSE          => 'perl_5',
	EXE_FILES        => ['bin/rpctiny'],
	PREREQ_PM => {
		'JSON' => 1,
		'IO::Socket::SSL' => 1,
		'Config::Tiny' => 0,
	},
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'https://github.com/bdzwillo/rpc-switch-client-tiny.git',
				web  => 'https://github.com/bdzwillo/rpc-switch-client-tiny',
			},
			bugtracker => {
				web => 'https://github.com/bdzwillo/rpc-switch-client-tiny/issues',
			},
		},
	},
);
