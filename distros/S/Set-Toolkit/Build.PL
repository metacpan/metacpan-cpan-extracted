use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Set::Toolkit',
    license             => 'perl',
    dist_author         => 'Sir Robert Burbridge <sirrobert@gmail.com>',
    dist_version_from   => 'lib/Set/Toolkit.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Set::Toolkit-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
