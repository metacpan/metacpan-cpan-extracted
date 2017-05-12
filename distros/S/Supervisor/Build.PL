use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Supervisor',
    license             => 'perl',
    dist_author         => 'Kevin L. Esteb <kesteb@wsipc.org>',
    dist_version_from   => 'lib/Supervisor.pm',
    build_requires => {
        'Badger'           => '0.06',
        'POE'              => '1.007',
        'DateTime'         => '0.4501',
        'File::Pid'        => 0,
        'Set::Light'       => '0.04',
        'Test::More'       => 0,
        'Config::IniFiles' => '2.39',
        'JSON'             => '2.15',
    },
    add_to_cleanup      => [ 'Supervisor-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
