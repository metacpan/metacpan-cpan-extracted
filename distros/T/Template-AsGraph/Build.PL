use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Template::AsGraph',
    license             => 'perl',
    dist_author         => 'Breno G. de Oliveira <garu@cpan.org>',
    dist_version_from   => 'lib/Template/AsGraph.pm',
	dist_abstract       => 'Create a graph from a Template Toolkit file',
    build_requires => {
        'Test::More'  => 0,
		'Template'    => 2,
		'File::Spec'  => 0,
		'Carp'        => 0,
		'Graph::Easy' => 0,
    },
    add_to_cleanup      => [ 'Template-AsGraph-*' ],
    create_makefile_pl => 'traditional',
	meta_merge => {
		resources => {
			repository => 'http://github.com/garu/Template-AsGraph',
		},
	}
);

$builder->create_build_script();
