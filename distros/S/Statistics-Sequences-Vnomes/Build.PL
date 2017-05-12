use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'Statistics::Sequences::Vnomes',
    license            => 'perl',
    dist_author        => q{Roderick Garton <rgarton@cpan.org>},
    dist_version_from  => 'lib/Statistics/Sequences/Vnomes.pm',
    configure_requires => {
        'Module::Build' => 0.421,
    },
    build_requires => {
        'Test::More' => '0.98',
    },
    requires => {
        'perl'                     => 5.006,
        'Algorithm::Combinatorics' => '0.27',
        'Math::Cephes'             => '0.5304',
        'Statistics::Lite'         => '3.62',
        'Statistics::Zed'          => '0.10',
        'Statistics::Sequences'    => '0.13',
    },
    add_to_cleanup     => ['Statistics-Sequences-Vnomes-0.20-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

1;
