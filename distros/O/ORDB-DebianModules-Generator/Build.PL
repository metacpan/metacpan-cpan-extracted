use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'ORDB::DebianModules::Generator',
    license             => 'perl',
    dist_author         => 'Ryan Niebur <ryanryan52@gmail.com>',
    dist_version_from   => 'lib/ORDB/DebianModules/Generator.pm',
    build_requires => {
        'Test::More' => 0,
        'Debian::ModuleList' => 0,
        'DBI' => 0,
        'DBD::SQLite' => 0
    },
    requires => {
        'Debian::ModuleList' => 0,
        'DBI' => 0,
        'DBD::SQLite' => 0
    },
    add_to_cleanup      => [ 'ORDB-DebianModules-Generator-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
