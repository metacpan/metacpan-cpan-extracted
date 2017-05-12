use strict;
use warnings;
use Module::Build;

use 5.006;

my $builder = Module::Build->new(
    module_name           => 'Parse::Fedora::Packages',
    license               => 'perl',
    dist_author           => 'Gabor Szabo',
    create_makefile_pl    => 'traditional',
    create_readme         => 0,
    recursive_test_files  => 0,
    requires              => {
        'XML::Simple'          => '0',
    },
    build_requires        => {
        'Test::More'                => '0.47',
        'Test::NoWarnings'          => '0',
    },
);

$builder->create_build_script();
