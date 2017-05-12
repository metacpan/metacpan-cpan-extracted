use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Quote::Reference',
    license             => 'perl',
    dist_author         => 'Anthony Kilna <anthony@kilna.com>',
    dist_version_from   => 'lib/Quote/Reference.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl'           => '5.6.0',
        'Filter::Simple' => '0.80',
    },
    add_to_cleanup      => [ 'Quote-Reference-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
