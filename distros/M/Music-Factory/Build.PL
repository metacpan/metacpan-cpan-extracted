#!perl
use 5.26.0;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name        => 'Music::Factory',
    license            => 'bsd',
    dist_author        => q{Jeremy Mates <jmates@thrig.me>},
    dist_version_from  => 'lib/Music/Factory.pm',
    release_status     => 'stable',
    configure_requires => { 'Module::Build' => '0.4004', },
    test_requires      => {
        'Test2::V0' => '0.000060',
        'perl'      => '5.26.0',
    },
    sign     => 1,
    requires => {
        'Object::Pad' => '0.66',
        'perl'        => '5.26.0',
    },
    add_to_cleanup => [ 'Music-Factory-*', 't/*.midi' ],
    auto_features  => {
        dist_authoring => {
            description => "Create new distributions",
            requires    => { 'Archive::Tar' => 1.09, },
        },
    },
    meta_merge => {
        resources =>
          { repository => 'https://thrig.me/src/Music-Factory.git' }
    },
);
$builder->create_build_script();
