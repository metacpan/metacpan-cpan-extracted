#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Spreadsheet::SimpleExcel;

# data
my @data = map {
    my $row = $_;

    [
        map {
            sprintf "This is content for the cell in row %s/col %s",
                $row, $_
        } ( 1 .. 10 )
    ]
} ( 1 .. 30_000 );

my $worksheet = [ 'NAME', { -data => \@data } ];

# create a new instance
my $excel = Spreadsheet::SimpleExcel->new(
    -worksheets => [$worksheet],
    -big        => 1,
);

# add headers to 'NAME'
$excel->set_headers('NAME',[qw/this is a test/]);

my $file = 'my_big_excel.xls';
$excel->output_to_file( $file );

ok -f $file;

# test cleanup
#unlink $file; 

done_testing();
