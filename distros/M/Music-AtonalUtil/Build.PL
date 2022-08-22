#!perl
use 5.10.0;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name        => 'Music::AtonalUtil',
    license            => 'artistic_2',
    dist_author        => q{Jeremy Mates <jeremy.mates@gmail.com>},
    dist_version_from  => 'lib/Music/AtonalUtil.pm',
    release_status     => 'stable',
    configure_requires => { 'Module::Build' => '0.4004', },
    test_requires      => {
        'Test::Most' => 0,
        'lib'        => 0,
    },
    requires => {
        'Algorithm::Combinatorics' => 0,
        'Carp'                     => 0,
        'List::Util'               => 1.44,    # uniqnum
        'Scalar::Util'             => 0,
    },
    sign           => 1,
    add_to_cleanup => ['Music-AtonalUtil-*'],
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
