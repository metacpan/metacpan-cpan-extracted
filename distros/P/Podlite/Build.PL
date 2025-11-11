use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name        => 'Podlite',
    license            => 'perl',
    dist_author        => q{Aliaksandr Zahatski <zag@cpan.org>},
    dist_version_from  => 'lib/Podlite.pm',
    release_status     => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
    },
    requires => {
        'Filter::Simple' => 0,
        'Test::Pod'    => 1.22,
        'Test::Pod::Coverage' => 1.10,
    },
    add_to_cleanup => ['Podlite-*'],
    meta_merge     => {
        resources => {
            repository => 'git://github.com/zag/p5-Podlite.git',
            bugtracker => 'https://github.com/zag/p5-Podlite/issues'
        }
    },
);

$builder->create_build_script();
