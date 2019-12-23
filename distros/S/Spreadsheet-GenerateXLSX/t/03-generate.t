#!perl

#
# 03-generate.t
#
# generate a spreadsheet and check for warnings;
#

use strict;
use warnings;

use Test::Needs {
    'Spreadsheet::ParseXLSX' => 0.26,
};
use Test::More 0.88 tests => 1;
use Test::Warn 0.36;
use Spreadsheet::GenerateXLSX qw/ generate_xlsx /;

my $stem = $0;
$stem =~ s/\.t$//;
my $filename = "${stem}.xlsx";

my $var;
my $data = [ [ 'A', 'B', 'C' ], [ $var, undef, '' ] ];

warnings_like { generate_xlsx( $filename, $data ) } [], 'no warnings for undefined values';

unlink($filename);
if ($@) {
    BAIL_OUT($@);
}
