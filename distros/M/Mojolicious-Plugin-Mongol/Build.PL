#!/usr/bin/env perl

use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
	module_name => 'Mojolicious::Plugin::Mongol',

	dist_author => 'Tudor Marghidanu',
	dist_abstract => 'Mongol plugin for Mojolicious',

	# NOTE: Keep list sorted!
	requires => {
		'Mojolicious' => undef,
		'Mongol' => undef,
		'Moose' => undef,
		'Test::More' => undef,
		'Test::Pod::Coverage' => undef,
		'Test::Pod' => undef,
	},

	optional => { },
);

$builder->create_build_script();
