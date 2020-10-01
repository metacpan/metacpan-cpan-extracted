use strict;
use Test::More tests => 34;
use File::Basename 'dirname';
use Spreadsheet::ParseODS;
use Data::Dumper;

my $d = dirname($0);

for my $file (qw(hidden-cols.ods hidden-cols.fods)) {
    my $workbook = Spreadsheet::ParseODS->new()->parse("$d/$file");
    for my $sheet (qw(vhvhvh vhvhv vhhhvh)) {
        my $worksheet = $workbook->worksheet($sheet);

        my $colnum = 0;
        for my $col (split //, $sheet) {
            my $v_hidden = ($col eq 'h') ? 'hidden' : 'visible';
            is !!$worksheet->is_col_hidden( $colnum++ ),
               ($col eq 'h'),
               "Column '$col' is $v_hidden";
        };
    };
};
