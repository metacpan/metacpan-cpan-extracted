use strict;
use Test::More tests => 28;
use File::Basename 'dirname';
use Spreadsheet::ParseODS;
use Data::Dumper;

my $d = dirname($0);

for my $file (qw(hidden-rows.ods hidden-rows.fods)) {
    my $workbook = Spreadsheet::ParseODS->new()->parse("$d/$file");
    for my $sheet (qw(vhvhv vhvh vhhhv)) {
        my $worksheet = $workbook->worksheet($sheet);

        my $rownum = 0;
        for my $row (split //, $sheet) {
            my $v_hidden = ($row eq 'h') ? 'hidden' : 'visible';
            is !!$worksheet->is_row_hidden( $rownum++ ),
               ($row eq 'h'),
               "Row '$row' is $v_hidden";
        };
    };
};
