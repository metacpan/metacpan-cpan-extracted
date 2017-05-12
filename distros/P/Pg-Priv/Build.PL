use strict;
use warnings;
use Module::Build;

Module::Build->new(
    module_name        => 'Pg::Priv',
    license            => 'perl',
    configure_requires => {
        'Module::Build' => '0.30',
    },
    build_requires     => {
        'Module::Build'    => '0.30',
        'Test::More'       => '0.88',
    },
    requires           => {
        'perl'              => 5.008,
    },
    recommends         => {
        'Test::Pod'           => '1.41',
        'Test::Pod::Coverage' => '1.06',
    },
    meta_merge         => {
        resources => {
            homepage    => 'http://search.cpan.org/dist/Pg-Priv/',
            bugtracker  => 'http://github.com/theory/pg-priv/issues/',
            repository  => 'http://github.com/theory/pg-priv/tree/',
        }
    },
)->create_build_script;
