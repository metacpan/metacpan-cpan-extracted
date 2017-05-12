use Test::More tests => 5;
use FindBin qw();
use Data::Dumper;

use Spreadsheet::SimpleExcel;

# data for spreadsheet
my @header = qw(Header1 Header2);
my @data   = (['Row1Col1', 'Row1Col2'],
              ['Row2Col1', 'Row2Col2']);

# create a new instance
my $excel = Spreadsheet::SimpleExcel->new();
isa_ok( $excel, 'Spreadsheet::SimpleExcel' );                                          #  1

# add worksheets
$excel->add_worksheet('Name of Worksheet',{-headers => \@header, -data => \@data});
$excel->add_worksheet('Second Worksheet',{-data => \@data});
$excel->add_worksheet('Test');

my @names = ('Name of Worksheet','Second Worksheet','Test');
my $ref   = $excel->sheets;
is_deeply( \@names, $ref );                                                            #  2

is( $excel->current_sheet, 'Test' );                                                   #  3

# add a row into the middle
$excel->add_row_at('Name of Worksheet',1,[qw/new row/]);

# sort data of worksheet - ASC or DESC
$excel->sort_data('Name of Worksheet',0,'DESC');

# remove a worksheet
$excel->del_worksheet('Test');

$ref = $excel->sheets;
pop @names;
is_deeply( \@names, $ref);                                                             #  4

# sort worksheets
$excel->sort_worksheets('DESC');

$ref = $excel->sheets;
my @titles = reverse( @names );
is_deeply( \@titles, $ref );                                                           #  5

# create the spreadsheet
$excel->output();

# get the result as a string
my $spreadsheet = $excel->output_as_string();

# print result into a file and handle error
$excel->output_to_file("my_excel.xls") or die $excel->errstr();
$excel->output_to_file("my_excel2.xls",45000) or die $excel->errstr();

## or

# data
my @data2  = (['Row1Col1', 'Row1Col2'],
              ['Row2Col1', 'Row2Col2']);

my $worksheet = ['NAME',{-data => \@data2}];
# create a new instance
my $excel2    = Spreadsheet::SimpleExcel->new(-worksheets => [$worksheet]);

# add headers to 'NAME'
$excel2->set_headers('NAME',[qw/this is a test/]);
# append data to 'NAME'
$excel2->add_row('NAME',[qw/new row/]);

$excel2->output();

$excel2->output_to_XML('test.xml');

# test cleanup
unlink 'my_excel.xls'  if -e 'my_excel.xls';
unlink 'my_excel2.xls' if -e 'my_excel2.xls';
unlink 'test.xml'      if -e 'test.xml';