use v5.10.1;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Roku::LCD',
    license             => 'Artistic_2_0',
    dist_author         => q{Ed Outhwaite <edster@gmx.com>},
    dist_version_from   => 'lib/Roku/LCD.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Roku::RCP'   => 0,
        'Time::HiRes' => 0,
        'Readonly'    => 0,
        'Carp'        => 0,
    },
    add_to_cleanup     => [ 'Roku-RokuLCD-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
