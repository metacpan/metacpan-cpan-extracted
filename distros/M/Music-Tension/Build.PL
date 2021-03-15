#!perl
use 5.008;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name        => 'Music::Tension',
    license            => 'bsd',
    dist_author        => q{Jeremy Mates <jeremy.mates@gmail.com>},
    dist_version_from  => 'lib/Music/Tension.pm',
    release_status     => 'stable',
    configure_requires => { 'Module::Build' => '0.4004', },
    test_requires      => { 'Test::Most'    => '0', },
    requires           => {
        'Carp'         => '0',
        'List::Util'   => '0',
        'Scalar::Util' => '0',
    },
    sign           => 1,
    add_to_cleanup => ['Music-Tension-*'],
    auto_features  => {
        dist_authoring => {
            description => "Create new distributions",
            requires    => {
                'Archive::Tar'      => 1.09,
                'Module::Signature' => 0.21,
            },
        },
    },
    meta_merge =>
      { resources => { repository => 'https://github.com/thrig/Music-Tension' } },
);

$builder->create_build_script();
