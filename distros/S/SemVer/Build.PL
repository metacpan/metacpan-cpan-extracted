use strict;
use warnings;
use Module::Build;

Module::Build->new(
    module_name        => 'SemVer',
    license            => 'perl',
    configure_requires => {
        'Module::Build' => '0.30',
    },
    build_requires     => {
        'Module::Build'    => '0.30',
        'Test::More'       => '0.88',
    },
    requires           => {
        'version' => 0.82,
        'perl'    => 5.008001,
    },
    recommends         => {
        'Test::Pod'           => '1.41',
        'Test::Pod::Coverage' => '1.06',
    },
    meta_merge         => {
        resources => {
            homepage    => 'https://metacpan.org/release/SemVer',
            bugtracker  => 'https://github.com/theory/semver/issues/',
            repository  => 'https://github.com/theory/semver',
        }
    },
)->create_build_script;
