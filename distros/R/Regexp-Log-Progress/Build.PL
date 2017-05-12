use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Regexp::Log::Progress',
    license             => 'perl',
    dist_author         => q{Kevin L. Esteb <kesteb@wsipc.org>},
    dist_version_from   => 'lib/Regexp/Log/Progress.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl'        => '5.8.8',
        'Regexp::Log' => '0.0',
    },
    add_to_cleanup     => [ 'Regexp-Log-Progress-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
