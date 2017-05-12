use strict;
use warnings;

require 5.008003;

use Module::Build;

my $builder = Module::Build->new(
    build_requires     => { 'Test::More'    => '0',    },
    configure_requires => { 'Module::Build' => '0',    },
    create_makefile_pl => 'traditional',
    create_readme      => 1,
    license            => 'perl',
    meta_merge         => {
        resources      => {
            repository => 'http://github.com/briang/MooseX-PrivateSetters'
        }
    },
    module_name        => 'MooseX::PrivateSetters',
    requires           => { 'Moose'         => '0.94', },
);

$builder->create_build_script();
