use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Table::Simple',
    license             => 'perl',
    dist_author         => q{Mark Allen <mrallen1@yahoo.com>},
    dist_version_from   => 'lib/Table/Simple.pm',
    build_requires => {
        'Test::More' => 0,
		'Moose' => 0.94,
		'Carp' => 0,
		'namespace::autoclean' => 0,
		'Tie::IxHash' => 0,
    },
    add_to_cleanup      => [ 'Table-Simple-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
