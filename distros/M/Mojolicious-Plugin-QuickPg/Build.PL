use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Mojolicious::Plugin::QuickPg',
	license             => 'perl',
	dist_author         => 'Pavel Kuptsov <pkuptsov@gmail.com>',
	dist_version_from   => 'lib/Mojolicious/Plugin/QuickPg.pm',
	dist_abstract       => 'Mojolicious Plugin enables quick and simple access for Mojo::Pg',
	build_requires => {
		'Test::More' => 0,
	},
	requires => {
		'perl'           => 5.010001,
		'Mojo::Pg'       => 2.0,
		'Mojolicious'    => 6.0,
	},
	add_to_cleanup  => [],
	meta_merge => {
		resources => {
			repository => 'https://bitbucket.org/pkuptsov/mojo-pg-quick',
		},
		keywords => ['mojo', 'mojolicious', 'postgresql', 'mojo-pg', 'plugin'],
	},
	create_makefile_pl => 'traditional',
);

$builder->create_build_script();
