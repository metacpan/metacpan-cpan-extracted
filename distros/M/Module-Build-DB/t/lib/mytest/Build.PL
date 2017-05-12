use lib '/Users/david/dev/github/module-build-db/lib';
use strict;
use warnings;
use Module::Build::DB;

Module::Build::DB->new(
    module_name        => 'Foo',
    license            => 'perl',
    db_config_key      => 'dbi',
    db_client          => 'mysql',
    test_env           => {
        CATALYST_DEBUG  => 0,
        CATALYST_CONFIG => 'conf/test.yml',
    },
    configure_requires => {
        'Module::Build::DB' => '0.10',
    },
    build_requires     => {
        'Module::Build::DB' => '0.10',
        'Test::More'        => '0.70',
        'Test::Harness'     => '3.18',
    },
)->create_build_script;


