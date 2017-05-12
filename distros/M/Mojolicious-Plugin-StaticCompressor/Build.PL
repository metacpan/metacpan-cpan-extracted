use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Mojolicious::Plugin::StaticCompressor',
	license             => 'perl',
	dist_author         => 'Masanori Ohgita (http://ohgita.info)',
	dist_version_from   => 'lib/Mojolicious/Plugin/StaticCompressor.pm',
	requires => {
		'Test::More'					 => 0,
		'version'					 => 0,
		'Mojolicious'				 => '3.88',
		'Encode'					 	 => 0,
		'CSS::Minifier'				 => 0,
		'JavaScript::Minifier'		 => 0,
		'Mojo::Util'					 => 0,
		'Module::Build'				 => 0,
		'Test::Pod'		 			 => 0,
		'Test::Pod::Coverage'		 => '1.08',
		'FindBin'					 => 0,
		'File::Slurp'				 => 0,
		'Test::Perl::Critic'			 => 0,
		'File::Find'					 => 0,
	},
	add_to_cleanup      => [ 'Mojolicious-Plugin-StaticCompressor-*' ],
);

$builder->create_build_script();
