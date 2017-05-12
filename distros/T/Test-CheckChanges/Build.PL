# @(#) $Id$
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name   => 'Test::CheckChanges',
    license       => 'perl',
    requires => {
	'perl'		=> '5.006',
    },
    build_requires => {
        'Test::More' => 0,
    },
    recommends => {
        'Test::Pod' => 0,
        'Test::Pod::Coverage' => 0,
	'Module::Build' => 0,
    },
    sign           => 1,
    create_makefile_pl => 'traditional',
    create_readme => 1,
);

$builder->create_build_script;
