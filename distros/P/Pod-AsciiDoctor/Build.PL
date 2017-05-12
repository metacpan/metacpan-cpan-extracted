use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Pod::AsciiDoctor',
    license             => 'Apache_2_0',
    dist_author         => q{Balachandran Sivakumar <balachandran@balachandran.org>},
    dist_version_from   => 'lib/Pod/AsciiDoctor.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    add_to_cleanup     => [ 'Pod-AsciiDoctor-*' ],
    create_makefile_pl => 'traditional',
    meta_merge => {
        x_contributors => [
            'Abhisek Kumar Rout < akr.optimus@gmail.com >'
            ],
    }
);

$builder->create_build_script();
