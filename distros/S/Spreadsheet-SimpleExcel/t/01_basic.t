# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Spreadsheet-SimpleExcel.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
use FindBin qw();
use Data::Dumper;

BEGIN { use_ok('Spreadsheet::SimpleExcel') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Spreadsheet::SimpleExcel;


my @header = qw(Header!1 Header2);
my @data;
  
for my $i(0..5){
  for(reverse(3..9)){
    push(@data,[$i,$_]);
  }
}

# create a new instance
my $excel = Spreadsheet::SimpleExcel->new();
ok($excel && ref($excel) eq 'Spreadsheet::SimpleExcel');

# add worksheets
$excel->add_worksheet('Name of Worksheet',{-headers => \@header, -data => \@data});
my @sheets = $excel->sheets();
ok($sheets[0] eq 'Name of Worksheet');

my $err;
$excel->sort_data('Name of Worksheet',3,'DESC') or $err = $excel->errstr();
ok(index($err,'Index not in Array') != -1);


my $xml = $FindBin::Bin.'/test.xml';
unlink $xml if -e $xml;
$excel->output_to_XML($xml);
ok(-e $xml);
unlink $xml if -e $xml;

is($excel->current_sheet, 'Name of Worksheet');

my @tmp_data = @data;
$excel->add_worksheet('Test');
for my $data(@tmp_data){
    $excel->add_row($data);
}

is($excel->current_sheet,'Test');
is(scalar(@{$excel->{worksheets}->[1]->[1]->{'-data'}}),scalar(@data));

my $file = $FindBin::Bin.'/excel2.xls';
unlink $file if -e $file;
$excel->output_to_file($file);
ok(-e $file);
unlink $file if -e $file;