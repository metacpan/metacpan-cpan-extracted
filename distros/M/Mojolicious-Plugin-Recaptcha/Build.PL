#!/usr/bin/env perl

use strict;
use warnings;
use Module::Build;
my $builder = Module::Build->new(
	module_name       => 'Mojolicious::Plugin::Recaptcha',
	license           => 'perl',
	dist_author       => 'Dmitry Konstantinov <konstantinov.dmitry@gmail.com>',
	dist_version_from => 'lib/Mojolicious/Plugin/Recaptcha.pm',
	build_requires    => {
		'Test::More' => 0,
	},
	requires          => {
	    perl          => 5.006,
		'Mojolicious' => 4.82,
	},
	meta_merge => {
		resources => {
			repository => 'git://github.com/konstantinov/Mojolicious-Plugin-Recaptcha.git',
		},
		keywords  => [ qw(mojolicious recaptcha) ],
	},
	create_makefile_pl => 'traditional',
);

$builder->create_build_script();