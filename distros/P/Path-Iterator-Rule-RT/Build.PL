use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Path::Iterator::Rule::RT',
    license             => 'artistic_2',
    dist_author         => q{Robert Blackwell <robert@robertblackwell.com>},
    dist_version_from   => 'lib/Path/Iterator/Rule/RT.pm',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
	'Path::Iterator::Rule' => 1.008,
	'RT::Client::REST' => 0.45,
    },
    add_to_cleanup     => [ 'Path-Iterator-Rule-RT-*' ],
    create_makefile_pl => 'traditional',
    meta_add => {
    	resources => {
            repository => 'https://github.com/rblackwe/Path-Iterator-Rule-RT'
    	}
	},
);

$builder->create_build_script();
