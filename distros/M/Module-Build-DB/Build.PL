use strict;
use warnings;
use Module::Build;

Module::Build->new(
    module_name        => 'Module::Build::DB',
    license            => 'perl',
    configure_requires => {
        'Module::Build' => '0.36',
    },
    build_requires     => {
        'Module::Build' => '0.36',
        'Test::More'    => '0.70',
    },
    requires           => {
        'Config::Any'   => '0.17',
        'Module::Build' => '0.34',
        'TAP::Harness'  => '3.13',
        'DBI'           => '1.43',
    },
    recommends         => {
        'Test::Pod'           => '1.41',
        'Test::Pod::Coverage' => '1.06',
    },
    meta_merge         => {
        resources => {
            homepage    => 'http://search.cpan.org/dist/Module-Build-DB/',
            bugtracker  => 'http://github.com/theory/module-build-pg/issues/',
            repository  => 'http://github.com/theory/module-build-pg/tree/',
        }
    },
)->create_build_script;
