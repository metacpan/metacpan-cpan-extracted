#!/usr/bin/env perl

use strict;
use warnings;
use Module::Build;
my $builder = Module::Build->new(
	module_name       => 'Mojolicious::Plugin::CaptchaRenderer',
	license           => 'perl',
	dist_author       => 'Dmitry Konstantinov <konstantinov.dmitry@gmail.com>',
	dist_version_from => 'lib/Mojolicious/Plugin/CaptchaRenderer.pm',
	build_requires    => {
		'Test::More' => 0,
	},
	requires          => {
		'Mojolicious'   => 0,
		'Image::Magick' => 0,
		'File::Spec'    => 0,
		'File::Temp'    => 0,
	},
	meta_merge => {
		resources => {
			repository => 'git://github.com/konstantinov/Mojolicious-Plugin-CaptchaRenderer.git',
		},
		keywords  => [ qw(mojolicious captcha) ],
	},
	create_makefile_pl => 'traditional',
);

$builder->create_build_script();