#!perl
use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name        => 'Music::RhythmSet',
    license            => 'bsd',
    dist_author        => q{Jeremy Mates <jeremy.mates@gmail.com>},
    dist_version_from  => 'lib/Music/RhythmSet.pm',
    release_status     => 'stable',
    configure_requires => { 'Module::Build' => '0.4004', },
    test_requires      => {
        'MIDI'      => '0',
        'Test2::V0' => '0.000060',
        'perl'      => '5.24.0',
    },
    requires => {
        'List::GroupingPriorityQueue' => '0',
        'MIDI'                        => '0',
        'Moo'                         => '0',
        'Statistics::Lite'            => '0',
        'namespace::clean'            => '0',
        'perl'                        => '5.24.0',
    },
    sign           => 1,
    add_to_cleanup => [ 'Music-RhythmSet-*', 't/*.midi' ],
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
