use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Term::Colormap',
    license             => 'artistic_2',
    dist_author         => q{Felix Tubiana <felixtubiana@gmail.com>},
    dist_version_from   => 'lib/Term/Colormap.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl'          => '5.006',
        'Scalar::Util'  => 0,
        'Term::ReadKey' => 0,
    },
    add_to_cleanup     => [ 'Term-Colormap-*' ],
    create_makefile_pl => 'traditional',
    meta_merge => {
        resources => {
            repository => 'https://github.com/xxfelixxx/perl-term-colormap',
        },
    },
);

$builder->create_build_script();
