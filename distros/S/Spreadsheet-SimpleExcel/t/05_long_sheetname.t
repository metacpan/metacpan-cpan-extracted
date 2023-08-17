#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Spreadsheet::SimpleExcel;
use Capture::Tiny qw/capture/;

# data
my $file = 'my_excel.xls';

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

my $name = 'A' x 40;
my $worksheet = [ $name, { -data => \@data } ];

my $excel;

my ($stdout, $stderr) = capture {
   $excel = Spreadsheet::SimpleExcel->new(
       -worksheets => [$worksheet],
       -filename   => $file,
   );
};

like $stderr, qr/length of worksheet name/;

# add headers to 'NAME'
$excel->set_headers($name,[qw/this is a test/]);

$excel->output_to_file();

ok -f $file;

# test cleanup
unlink $file; 

done_testing();
