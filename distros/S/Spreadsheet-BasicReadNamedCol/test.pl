# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 15 };
use Spreadsheet::BasicReadNamedCol;
print 'Use it.................................';
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

## Can we create a log object
print 'Create object..........................';
my $ss;
ok( sub { $ss = Spreadsheet::BasicReadNamedCol->new('Test.xls'); } );


## Set columns
 my @columnHeadings = (
        'Heading Col A',
        'Heading Col C',
        'Heading Col B',
 );
 $ss->setColumns(@columnHeadings);



## Read from it
my $data = $ss->getNextRow();
print "Reading row, (", scalar(@$data), ") columns...............";
ok( scalar(@$data), 3 );


## Get the sheet name
my $name = $ss->currentSheetName();
print "Getting sheet name ($name).......";
ok( $name, "/Test Sheet1/" );

## Get the number of sheets
my $cnt = $ss->numSheets();
print "Getting number sheets ($cnt)..............";
ok( $cnt, 3 );

## Test we can read all the data
print "Dumping the entire spreadsheet:\n";
print " Expecting Sht1: 3 row x 3 col, Sht2: 2 row x 3 col, Sht 3: 1 row x 3 col:\n";
print " Expecting columns to come out as: 'Heading Col A', 'Heading Col C', 'Heading Col B' \n";
my $rows = 0;
$ss->getFirstSheet();
my @header_row;
do
{
	print '  *** ', $ss->currentSheetName(), " ***\n";

	# Print the row number and data for each row of the
	# spreadsheet to stdout using '|' as a separator
	my $sheet_row_count = 0;
	while (my $data = $ss->getNextRow())
	{
		no warnings qw(uninitialized);
		$sheet_row_count++;
		$header_row[$ss->currentSheetNum()] = $data if ($sheet_row_count eq 1);
		$rows++;
		print '  ', join('|', $row, @$data), "\n";
	}
} while ($ss->getNextSheet());
ok( $rows, 9 );

# Test we got the columns in the order we specified (ie "Heading Col A", "Heading Col C", "Heading Col B" )
print "First sheet,  our col=0, real col=0....";
ok( $header_row[0]->[0], "/Heading Col A/");
print "First sheet,  our col=1, real col=2....";
ok( $header_row[0]->[1], "/Heading Col C/");
print "First sheet,  our col=2, real col=1....";
ok( $header_row[0]->[2], "/Heading Col B/");

print "Second sheet, our col=0, real col=0....";
ok( $header_row[1]->[0], "/Heading Col A/");
print "Second sheet, our col=1, real col=2....";
ok( $header_row[1]->[1], "/Heading Col C/");
print "Second sheet, our col=2, real col=1....";
ok( $header_row[1]->[2], "/Heading Col B/");

print "Third sheet,  our col=0, real col=0....";
ok( $header_row[2]->[0], "/Heading Col A/");
print "Third sheet,  our col=1, real col=2....";
ok( $header_row[2]->[1], "/Heading Col C/");
print "Third sheet,  our col=2, real col=1....";
ok( $header_row[2]->[2], "/Heading Col B/");

#---<end of File >---#