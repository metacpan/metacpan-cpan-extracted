use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'RDF::SKOS',
    license             => 'perl',
    dist_author         => 'Robert Barta <drrho@cpan.org>',
    dist_version_from   => 'lib/RDF/SKOS.pm',
    build_requires => {
        'Test::More' => 0,
	'Text::CSV_XS' => 0,
	'Test::Pod::Coverage' => 0,
	'Test::Pod' => 0,
	'RDF::Redland' => 0,
    },
    add_to_cleanup      => [ 'RDF-SKOS-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
