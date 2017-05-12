use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Spreadsheet::DataToExcel',
    license             => 'perl',
    dist_author         => q|'Zoffix <'zoffix@cpan.org'>|,
    dist_version_from   => 'lib/Spreadsheet/DataToExcel.pm',
    build_requires => {
        'Test::More' => 0,
    },
    configure_requires => { 'Module::Build' => 0 },
    build_recommends => {
        'App::ZofCMS::Test::Plugin' => '0.0104',
    },
    requires => {
        'Class::Data::Accessor'   => 0.04004,
        'Spreadsheet::WriteExcel' => 2.25,
        perl                      => '5.006',
    },
    add_to_cleanup      => [ 'Spreadsheet-DataToExcel-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
