use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'ORDB::DebianModules',
    license             => 'perl',
    dist_author         => 'Ryan Niebur <ryanryan52@gmail.com>',
    dist_version_from   => 'lib/ORDB/DebianModules.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
         'ORLite::Mirror' => '1.15',
         'Params::Util' => '0',
    },
    add_to_cleanup      => [ 'ORDB-DebianModules-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
