#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Spreadsheet::SimpleExcel;

# data
my $file = 'my_excel.xlsx';

unlink $file; 
ok !-f $file;

my @data = map {
    my $row = $_;

    [
        map {
            sprintf "This is content for the cell in row %s/col %s",
                $row, $_
        } ( 1 .. 60 )
    ]
} ( 1 .. 30 );

my $worksheet = [ 'NAME', { -data => \@data } ];

# create a new instance
my $excel = Spreadsheet::SimpleExcel->new(
    -worksheets => [$worksheet],
    -filename   => $file,
    -format     => 'xlsx',
);

# add headers to 'NAME'
$excel->set_headers('NAME',[qw/this is a test/]);

$excel->output_to_file();

ok -f $file;

# test cleanup
unlink $file; 

done_testing();
