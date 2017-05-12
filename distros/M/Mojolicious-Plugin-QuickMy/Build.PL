use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Mojolicious::Plugin::QuickMy',
	license             => 'perl',
	dist_author         => 'Pavel Kuptsov <pkuptsov@gmail.com>',
	dist_version_from   => 'lib/Mojolicious/Plugin/QuickMy.pm',
	dist_abstract       => 'Mojolicious Plugin enables quick and simple access for Mojo::mysql',
	build_requires => {
		'Test::More' => 0,
	},
	requires => {
		'perl'           => 5.010001,
		'Mojo::mysql'       => 0.14,
		'Mojolicious'    => 6.0,
	},
	add_to_cleanup  => [],
	meta_merge => {
		resources => {
			repository => 'https://bitbucket.org/pkuptsov/mojolicious-plugin-quickmy',
		},
		keywords => ['mojo', 'mojolicious', 'mysql', 'mojo-mysql', 'plugin'],
	},
	create_makefile_pl => 'traditional',
);

$builder->create_build_script();
