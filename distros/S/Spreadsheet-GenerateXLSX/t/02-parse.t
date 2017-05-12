#!perl

#
# 02-parse.t
#
# generate a spreadsheet, then parse it to check
# that the spreadsheet contains the expected data
#

use strict;
use warnings;

use Test::Needs {
    'Spreadsheet::ParseXLSX' => 0.26,
};
use Test::More 0.88 tests => 1;
use Spreadsheet::GenerateXLSX qw/ generate_xlsx /;
my $stem = $0;
$stem =~ s/\.t$//;

my $nrows = 5;
my $ncols = 7;
my $filename = "${stem}.xlsx";

my $data = generate_data($nrows, $ncols);

generate_xlsx($filename, $data);

eval {
    my $parser   = Spreadsheet::ParseXLSX->new
                   // die "can't instantiate XLSX parser\n";
    my $workbook = $parser->parse($filename)
                   || die "can't parse generated spreadsheet $filename\n";
    my @sheets   = $workbook->worksheets();

    if (@sheets != 1) {
        die(sprintf("unexpected number of worksheets (%d) in %s\n",
                     int(@sheets), $filename));
    }

    my $sheet = $sheets[0];

    my ($row_min, $row_max) = $sheet->row_range;
    my ($col_min, $col_max) = $sheet->col_range;

    if ($row_min != 0 || $row_max != $nrows - 1) {
        die "unexpected row range $row_min..$row_max -- was expecting 0..$nrows\n";
    }

    if ($col_min != 0 || $col_max != $ncols - 1) {
        die "unexpected col range $col_min..$col_max -- was expecting 0..$ncols\n";
    }

    for (my $r = 0; $r < $nrows; $r++) {
        for (my $c = 0; $c < $ncols; $c++) {
            my $expected = $data->[$r]->[$c];
            my $cell     = $sheet->get_cell($r, $c);
            my $got      = $cell->value();
            if ($got ne $expected) {
                die sprintf("value in cell ($r,$c) was \"%s\" but we wrote \"$expected\"\n",
                            ($got // 'undef'));
            }
        }
    }

};
unlink($filename);
if ($@) {
    BAIL_OUT($@);
}

ok(1, "read back a spreadsheet we just generated");

sub generate_data
{
    my ($nrows, $ncols) = @_;
    my $data = [];

    for (my $r = 0; $r < $nrows; $r++) {
        my $row = [];
        for (my $c = 0; $c < $ncols; $c++) {
            push(@$row, "cell${r}${c}");
        }
        push(@$data, $row);
    }

    return $data;
}

