use v5;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name        => 'Scalar::ValueTags::LineageTracking',
    dist_author        => 'Noel Maddy <ZHTWN@cpan.org',
    configure_requires => {
        'Module::Build' => "0.4004",    # test_requires
    },
    requires => {
        'perl' => '5.044',
        'Carp' => 0,
        'Ref::Util' => 0,
        'Scalar::ValueTags' => '0.004',
    },
    test_requires => {
        'Test2::V0' => 0,
    },
    license         => 'perl',
    create_license  => 1,
    create_manifest => 1,
    create_readme   => 1,
    add_to_cleanup  => [
        'MANIFEST',
        'META.*',
    ],
    meta_merge      => {
        resources => {
            license    => 'https://dev.perl.org/licences/',
            bugtracker => 'https://github.com/Zhtwn/Scalar-ValueTags-LineageTracking/issues',
            repository => 'git://github.com/Zhtwn/Scalar-ValueTags-LineageTracking.git',
        },
    },
);

$build->create_build_script;
