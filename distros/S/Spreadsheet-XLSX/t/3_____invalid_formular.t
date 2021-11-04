use strict;
use warnings;
use Test::More;
use Spreadsheet::XLSX;

BEGIN {
    if( !$ENV{RELEASE_TESTING} ) {
        plan skip_all => 'these tests are for release candidate testing';
    }else{
        eval{
            require Test::Warnings;
            Test::Warnings->import(('warning', ':no_end_test'));
            1;
        } or do {
            plan skip_all => 'Skipping this test because Test::Warnings is not installed';
        };
    }
}

plan tests => 1;

my $fn = __FILE__;

$fn =~ s{t$}{xlsx};

my $warning = warning { my $excel = Spreadsheet::XLSX->new($fn); };
unlike(
    $warning,
    qr/isn't numeric/,
    'got a "isn\'t numeric" warning when parsing the Excel file',
) or diag 'got warning(s): ', explain($warning);
