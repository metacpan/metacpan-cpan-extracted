use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Plack::App::CLI',
    license             => 'perl',
    dist_author         => q{Dalibor Horinek <dal@horinek.net>},
    dist_version_from   => 'lib/Plack/App/CLI.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
    },
    add_to_cleanup      => [ 'Plack-App-CLI-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
