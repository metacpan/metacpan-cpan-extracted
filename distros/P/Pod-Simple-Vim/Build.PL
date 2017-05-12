use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Pod::Simple::Vim',
    license             => 'perl',
    dist_author         => 'Petar Shangov <pshangov@yahoo.com>',
    dist_version_from   => 'lib/Pod/Simple/Vim.pm',
    build_requires => {
        'Test::More'        => 0,
		'Test::Differences' => 0,
    },
	requires => {
		'Pod::Simple' => 0,
	},
    add_to_cleanup      => [ 'Pod-Simple-Vim-*' ],
	create_makefile_pl => 'passthrough',
);

$builder->create_build_script();
