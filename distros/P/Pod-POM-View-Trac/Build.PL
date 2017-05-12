use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Pod::POM::View::Trac',
    license             => 'perl',
    dist_author         => q{Kevin L. Esteb <kevin@kesteb.us>},
    dist_version_from   => 'lib/Pod/POM/View/Trac.pm',
    configure_requires  => { 
        'Module::Build' => 0.40 
    }, 
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl'     => 5.006,
        'Pod::POM' => 0.0,
    },
    add_to_cleanup      => [ 'Pod-POM-View-Trac-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
