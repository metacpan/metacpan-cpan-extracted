#!/usr/bin/env perl

use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
	module_name => 'Mongol',

	dist_author => 'Tudor Marghidanu',
	dist_abstract => 'Perl MongoDB wrapper for Moose objects',

	meta_merge => {
		resources => {
			repository => 'https://github.com/marghidanu/mongol'
		},

		x_contributors => [
			'Tudor Marghidanu <tudor@marghidanu.com>',
		],
	},

	license => 'artistic_2',

	# NOTE: Keep list sorted!
	requires => {
		'Class::Load' => undef,
		'Data::UUID' => undef,
		'Lingua::EN::Inflect' => undef,
		'MongoDB' => undef,
		'Moose' => undef,
		'MooseX::ClassAttribute' => undef,
		'MooseX::Storage::Base::SerializedClass' => undef,
		'MooseX::Storage' => undef,
		'Test::More' => undef,
		'Test::Pod::Coverage' => undef,
		'Test::Pod' => undef,
	},

	optional => { },
);

$builder->create_build_script();
