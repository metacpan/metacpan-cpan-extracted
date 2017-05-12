use 5.008008;
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name        => 'RPSL::Parser',
    dist_version_from  => 'lib/RPSL/Parser.pm',
    dist_author        => 'Luis Motta Campos <lmc@bitbistro.com>',
    requires           => { 'Class::Accessor' => 0.31 },
    build_requires     => { 'Test::More' => 0, 'Test::Harness' => 2.62, },
    license            => 'perl',
    create_makefile_pl => 'traditional',
);

$build->create_build_script;
