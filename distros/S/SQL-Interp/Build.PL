use Module::Build;

Module::Build->new(
    module_name => 'SQL::Interp',
    license => 'perl',
#    'release_status' => 'testing',
    configure_requires => { 'Module::Build' => 0.38 },
    requires => {
        DBI             => 1.00,
        perl            => '5.8.0',
        'Sub::Exporter' => 0,
    },
    recommends => {
        Scalar::Util   => 0
    },
    create_makefile_pl  => 'traditional',
    dist_author => [
        'David Manura',
        'Mark Stosberg <mark@summersault.com>',
        'Yoran Heling <projects@yorhel.nl>'
    ],
    meta_merge => {
        resources => {
            repository => 'https://code.blicky.net/yorhel/SQL-Interp',
        },
    },
)->create_build_script();
