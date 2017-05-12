#! perl

BEGIN { require 5.006002 }

use Module::Build;

my $build = Module::Build->new(
    module_name => 'SUPER',
    license     => 'perl',
    requires    =>
    {
        'perl'          => '5.6.2',
        'Scalar::Util'  => '1.20',
        'Sub::Identify' => '0.03',
    },
    build_requires =>
    {
        'Test::Simple' => '0.61',
    },
    no_index     =>
    {
        package => [ qw( UNIVERSAL DB ) ]
    },
);

$build->create_build_script();
