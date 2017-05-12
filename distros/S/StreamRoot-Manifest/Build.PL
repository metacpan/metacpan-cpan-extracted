use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'StreamRoot::Manifest',
    license             => 'Artistic_2_0',
    dist_author         => q{Lucas Tiago de Moraes <lucastiagodemoraes@gmail.com>},
    dist_version_from   => 'lib/StreamRoot/Manifest.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'WWW::Curl' => 0,
        'JSON' => 0,
    },
    add_to_cleanup     => [ 'StreamRoot-Manifest-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
