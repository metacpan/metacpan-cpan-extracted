use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Object::eBay',
    license             => 'perl',
    dist_version_from   => 'lib/Object/eBay.pm',
    create_makefile_pl  => 'passthrough',
    requires => {
        'Class::Std'   => '0.0.8',
        'Net::eBay'    => '0.28',
        'Scalar::Util' => '1.02',
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Object-eBay-*' ],
    meta_merge => {
        resources => {
            repository => 'https://github.com/mndrix/Object-eBay',
        },
    },
);

$builder->create_build_script();
