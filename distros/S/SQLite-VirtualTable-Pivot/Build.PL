use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'SQLite::VirtualTable::Pivot',
    license             => 'perl',
    dist_abstract       => "Manipulate pivot tables using sqlite virtual tables",
    dist_author         => q{Brian Duggan <bduggan@matatu.org>},
    dist_version_from   => 'lib/SQLite/VirtualTable/Pivot.pm',
    build_requires => {
        'Test::More'           => 0,
        'DBI'                  => 0,
        'DBIx::Simple'         => 0,
        'DBD::SQLite'          => '1.25',
        'SQLite::VirtualTable' => 0,
        'Class::Accessor::Contextual' => 0,
        'Scalar::Util'         => 0,
      },
    add_to_cleanup      => [ 'SQLite-VirtualTable-Pivot-*' ],
    create_makefile_pl => 'traditional',
    meta_merge => {
        resources => {
            repository => 'http://github.com/bduggan/SQLite-VirtualTable-Pivot/tree/master',
        }
    }
);

$builder->create_build_script();
