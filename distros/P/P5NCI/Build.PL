#! perl

use strict;
use warnings;

BEGIN { require 5.006002 }

use lib 'build_lib';
use P5NCI::Build;

my $build = P5NCI::Build->new(
    module_name    => 'P5NCI',
    license        => 'perl',
    requires       => {},
    xs_files       => { 'lib/P5NCI.xs' => 'lib/P5NCI.xs' },
    requires       =>
    {
        'Test::Exception'    => '0.19',
        'Test::Simple'       => '0.47',
    },
    build_requires =>
    {
        'ExtUtils::CBuilder' => '0.03',
    },
    dist_version_from => 'lib/P5NCI.pm',
);

$build->create_build_script();
