#!/usr/bin/perl

use strict;

use Module::Build;

Module::Build->new(
	'module_name'        => 'MogileFS::Client::Fuse',
	'create_makefile_pl' => 'traditional',
	'dist_abstract'      => 'Fuse binding for MogileFS',
	'dist_author'        => 'Daniel Frett <daniel.frett@gmail.com>',
	'license'            => 'bsd',
	'meta_merge'         => {
		'resources' => {
			'license'    => 'http://www.opensource.org/licenses/BSD-3-Clause',
			'repository' => 'https://github.com/frett/MogileFS-Fuse',
		},
	},
	'configure_requires' => {
		'Module::Build'               => '0.36',
	},
	'build_requires'     => {
		'Test::More'                  => 0,
	},
	'requires'           => {
		'Fuse'                        => '0.11',
		'MogileFS::Client::FilePaths' => 0,
		'MRO::Compat'                 => 0,
		'Params::Validate'            => 0,
		'Scalar::Util'                => 0,
		'threads::shared'             => '1.21',
	},
)->create_build_script();
