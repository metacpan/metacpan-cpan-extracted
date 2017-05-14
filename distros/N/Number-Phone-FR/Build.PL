#!/usr/bin/env perl
use utf8;   # vim:set ts=4 sw=4 sts=4:

use strict;
use warnings;

use Module::Build;
use File::Spec;

my $build_module = 'Module::Build';

my $FR_Full_pm = File::Spec->catfile(qw(lib Number Phone FR Full.pm));

# Use the extended build only in author environment
if (-d '.git' || ! -f $FR_Full_pm) {
	print "Building in author mode\n";
	$build_module = 'inc::Build::Author';
	unshift @INC, '.';
    require inc::Build::Author;
}

my $builder = $build_module->new(
	module_name          => 'Number::Phone::FR',
	dist_author          => 'Olivier Mengué <dolmen@cpan.org>',
    dist_abstract        => 'Phone number information for France (+33)',
    # Defaults to FR.pm if FR/Full.pm has not yet been built
    dist_version_from    => (grep { -e $_ } ('lib/Number/Phone/FR/Full.pm', 'lib/Number/Phone/FR.pm'))[0],
	license              => 'perl',
	meta_add             => {
		resources => {
			homepage => 'https://github.com/dolmen/p5-Number-Phone-FR',
			repository => 'https://github.com/dolmen/p5-Number-Phone-FR.git',
			bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Number-Phone-FR',
		},
	},
	requires => {
		'perl' => '5.008001',
		'Number::Phone' => '1.7004',
		'parent' => '0.221',
		'Scalar::Util' => 0,
		'Carp' => 0,
	},
	configure_requires => {
		'Module::Build' => '0.36',
        'File::Spec' => 0,
	},
	build_requires => {
		'Test::More' => '0.94',
        'Test::NoWarnings' => '1.02',
	},
);

$builder->create_build_script;

