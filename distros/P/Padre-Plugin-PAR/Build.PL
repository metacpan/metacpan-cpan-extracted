use 5.008;
use strict;
use warnings;

use Padre::PluginBuilder ();

my $builder = Padre::PluginBuilder->new(
    module_name           => 'Padre::Plugin::PAR',
    license               => 'perl',
    dist_author           => ['Gabor Szabo', 'Steffen Mueller'],
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

        'PAR::Packer'             => 1.005,
        'Padre'                   => 0.43,
    },
    build_requires        => {
        'Test::More'              => '0.47',
    },
    meta_merge     => {
        resources => {
            homepage   => 'http://padre.perlide.org/',
            repository => 'http://svn.perlide.org/padre/trunk/Padre-Plugin-PAR/',
        }
    },
    share_dir => 'share',
);

$builder->create_build_script();
