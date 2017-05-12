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
        Text::Balanced => '1.87',
        Filter::Simple => 0,
        Scalar::Util   => 0
    },
    create_makefile_pl  => 'traditional',
    dist_author => [ 'David Manura (http://math2.org/david/contact)' , 'Mark Stosberg <mark@summersault.com>' ],
    meta_merge => {
        resources => {
            repository => 'https://github.com/markstos/SQL-Interp',
        },
    },
)->create_build_script();
