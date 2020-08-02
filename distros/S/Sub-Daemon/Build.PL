#!/usr/bin/env perl
use strict;
use warnings;
use Module::Build;

Module::Build->new(
	module_name         => 'Sub::Daemon',
	dist_abstract       => 'Perl class for creating daemons',
	license             => 'perl',
	dist_author         => 'trunaev <trunaev@gmail.com>',
	dist_version_from   => 'lib/Sub/Daemon.pm',
	build_requires      => {'Test::More' => 0,},
	configure_requires  => { 'Module::Build' => '0.40', },
	requires => {
		'perl'		=> 5.014,
		'AnyEvent'	=> 0,
		'POSIX'		=> 0,
		'File::Pid'	=> 0,
		'Carp'		=> 0,
		'Fcntl'		=> 0,
	},
	meta_merge => {
		resources => {
			repository => 'https://github.com/trunaev/sub-daemon',
		},
		keywords => [ qw/Perl Daemon fork workers child processes/ ],
	},
	add_to_cleanup     => [],
	create_makefile_pl => 'traditional',
)->create_build_script();