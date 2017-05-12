use v5.16;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'OS::CheckUpdates::AUR',
    license             => 'artistic_2',
    dist_author         => q{3ED <krzysztof1987@gmail.com>},
    dist_version_from   => 'lib/OS/CheckUpdates/AUR.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'WWW::AUR'              => 0.19,
        'JSON'                  => 0,
        'Try::Tiny'             => 0,
    },
    add_to_cleanup     => [ 'OS-CheckUpdates-AUR-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
