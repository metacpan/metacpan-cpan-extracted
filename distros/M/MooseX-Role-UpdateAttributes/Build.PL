#!/usr/bin/env perl

use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
	module_name => 'MooseX::Role::UpdateAttributes',

	dist_author => 'Tudor Marghidanu',
	dist_abstract => 'Update instance attributes ar once',

	meta_merge => {
		resources => {
			repository => 'https://github.com/marghidanu/moosex-role-update-attributes'
		},

		x_contributors => [
			'Tudor Marghidanu <tudor@marghidanu.com>',
		],
	},

	license => 'artistic_2',

	# NOTE: Keep list sorted!
	requires => {
		'Moose' => undef,
		'Test::More' => undef,
		'Test::Pod' => undef,
		'Test::Pod::Coverage' => undef,
	},

	optional => { },
);

$builder->create_build_script();
