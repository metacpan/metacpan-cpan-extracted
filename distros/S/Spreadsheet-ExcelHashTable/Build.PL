use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Spreadsheet::ExcelHashTable',
    dist_abstract       => 'Converts Excel Tables to perl Hash',
    license             => 'perl',
    dist_author         => q{Srinik <srinik.perl@gmail.com>},
    dist_version_from   => 'lib/Spreadsheet/ExcelHashTable.pm',
    build_requires => {
        'Test::More' => 0,
	'Spreadsheet::ParseExcel' => 0,
	'Spreadsheet::WriteExcel' => 0,
	'Tie::IxHash' => 0,
    },
    requires => {
        'perl' => 5.006,
    },
    add_to_cleanup      => [ 'Spreadsheet-ExcelHashTable-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
