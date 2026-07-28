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
        'LICENSE',
        'MANIFEST',
        'META.*',
        'README',
    ],
);

$build->create_build_script;
