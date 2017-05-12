use 5.012;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'SysConf',
    license             => 'gpl',
    dist_author         => q{Joe Landman <landman@scalableinformatics.com>},
    dist_version_from   => 'lib/SysConf.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Switch'              => 2.15,
        #'Foo::Bar::Module' => 5.0401,
    },
    add_to_cleanup     => [ 'SysConf-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
