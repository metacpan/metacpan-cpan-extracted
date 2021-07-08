#!perl
use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name        => 'Music::Guidonian',
    license            => 'bsd',
    dist_author        => q{Jeremy Mates <jeremy.mates@gmail.com>},
    dist_version_from  => 'lib/Music/Guidonian.pm',
    release_status     => 'stable',
    configure_requires => { 'Module::Build' => '0.4004', },
    test_requires      => {
        'Music::Scales' => '0',
        'Test2::V0'     => '0.000060',
        'perl'          => '5.24.0',
    },
    requires => {
        'List::Util'       => '0',
        'List::UtilsBy'    => '0',
        'Moo'              => '0',
        'Music::PitchNum'  => '0',
        'namespace::clean' => '0',
        'perl'             => '5.24.0',
    },
    sign           => 1,
    add_to_cleanup => ['Music-Guidonian-*'],
    auto_features  => {
        dist_authoring => {
            description => "Create new distributions",
            requires    => {
                'Archive::Tar'      => 1.09,
                'Module::Signature' => 0.21,
            },
        },
    },
);

$builder->create_build_script();
