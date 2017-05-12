use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Set::SortedArray',
    license             => 'perl',
    dist_author         => q{"Kevin Galinsky" <"kgalinsky plus cpan at gmail dot com">},
    dist_version_from   => 'lib/Set/SortedArray.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
    },
    add_to_cleanup      => [ 'Set-SortedArray-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
