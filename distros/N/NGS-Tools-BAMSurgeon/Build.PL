# Safe Perl
use strict;
use autodie;

use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'NGS::Tools::BAMSurgeon',
	license             => 'perl',
	dist_author         => ['Christopher Lalansingh  <clalansingh@oicr.on.ca>'],

	dist_version_from   => 'lib/NGS/Tools/BAMSurgeon.pm',
	dist_abstract       => 'This package is a pipeline wrapper for BAMSurgeon (https://github.com/adamewing/bamsurgeon) and provides additional functionality for the simulation of copy number abberations in the tumour.',

	build_requires => {
		'Test::More' => 0,
		'FindBin' => 0
	},

	configure_requires => {
		'Module::Build'
	},	

	share_dir => 'share',

	# Modules required to use this module
	requires => {
		'HPCI' => 0,
		'Moose' => 0,
		'Pod::Usage' => 0,
		'YAML' => 0,
		'FindBin' => 0,
		'Data::Dumper' => 0,
		'Params::Validate' => 0,
		'File::Path' => 0,
		'Cwd' => 0,
		'Moose::Util' => 0,
		'Moose::Role' => 0,
		'List::Util' => 0,
		'List::MoreUtils' => 0,
		'File::Basename' => 0,
		'File::Copy' => 0
	}
);

$builder->create_build_script();
