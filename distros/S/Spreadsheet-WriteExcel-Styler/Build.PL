use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Spreadsheet::WriteExcel::Styler',
    license             => 'perl',
    dist_author         => q{Laurent Dami <laurent.dami AT etat ge ch>},
    dist_version_from   => 'lib/Spreadsheet/WriteExcel/Styler.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Spreadsheet-WriteExcel-Styler-*' ],
);

$builder->create_build_script();
