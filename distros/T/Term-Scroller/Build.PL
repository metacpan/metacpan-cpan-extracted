use 5.008;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name         => 'Term::Scroller',
    license             => 'perl_5',
    dist_author         => q{Cameron Tauxe <camerontauxe@gmail.com>},
    dist_version_from   => 'lib/Term/Scroller.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
    },
    requires => {
        'perl'              => '5.020',
        'IO::Pty'           => '1.14',
        'Term::ReadKey'     => '2.38',
        'Encode::Locale'    => '1.05'
    },
    add_to_cleanup     => [ 'Term-Scroller-*' ],
    meta_merge  => {
        resources => {
            repository => 'https://github.com/camtauxe/term-scroller.git'
        }
    }
);

$builder->create_build_script();
