#!/usr/bin/env perl
use strict;
use warnings;

use Module::Build;

my $build = new Module::Build(
	'module_name' => 'ResourcePool::Resource::Redis',
	'license' => 'mit',
	'configure_requires' => {
		'Module::Build' => '>= 0.011',
	},
	'build_requires' => {
		'Test::More' => '',
		'Test::MockModule' => '',
	},
	'requires' => {
		'perl' => '>= v5.6',
		'Redis' => '',
		'ResourcePool::Factory' => '',
		'ResourcePool::Resource' => '',
	},
	'recursive_test_files' => 1,
);
$build->create_build_script();

