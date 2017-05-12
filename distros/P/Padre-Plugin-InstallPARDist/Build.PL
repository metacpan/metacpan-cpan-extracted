use 5.008;
use strict;
use warnings;

use Padre::PluginBuilder ();

my $builder = Padre::PluginBuilder->new(
    module_name           => 'Padre::Plugin::InstallPARDist',
    license               => 'perl',
    dist_author           => 'Steffen Mueller',
    create_makefile_pl    => 'traditional',
    create_readme         => 0,
    recursive_test_files  => 0,

    configure_requires    => {
        'Padre::PluginBuilder'    => '0.12',
    },
    requires              => {
        'perl'                    => '5.008',

        'Carp'                    => 0,
        'Cwd'                     => 0,
        'Data::Dumper'            => 0,

        'ExtUtils::InferConfig'   => '1.03',
        'ExtUtils::InstallPAR'    => '0.03',
        'LWP::Simple'             => '0',
        'Padre'                   => '0.12',
    },
    build_requires        => {
        'Test::More'              => '0.47',
    },
);

$builder->create_build_script();
