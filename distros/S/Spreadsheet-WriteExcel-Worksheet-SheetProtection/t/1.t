use strict;
use Test::More;

BEGIN { plan tests => 5 };

use Spreadsheet::WriteExcel;
use Spreadsheet::WriteExcel::Worksheet::SheetProtection;
ok(1); # If we made it this far, we're ok.

my $test_file = 'test.xls';

## Create a test spreadsheet
my $wb = Spreadsheet::WriteExcel->new($test_file);
my $ws = $wb->add_worksheet;

## Test default protection
is $ws->sheet_protection, 0x4400,	"Default protection";

## Test specifying via hash
$ws->sheet_protection(
			-select_locked_cells => 0,
			"Format Columns" => 1 );
is $ws->sheet_protection, 0x4008,	"Set hash protection";

## Test specifying via number
$ws->sheet_protection(0x1234);
is $ws->sheet_protection, 0x1234,	"Set numeric protection";

## Test that it gets saved

# Close spreadsheet object
$wb->close;

SKIP: {
	skip "Test file '$test_file' doesn't exist", 1 if !(-f $test_file);
	
	# Read binary file
	my $fh;
	my $contents = '';
	my $buffer;
	
	open $fh, $test_file or die "Can't open test file";
	binmode $fh;
	while (read($fh, $buffer, 1024)) {
		$contents .= $buffer;
	}
	close $fh;
	
	# Test for magic string
	
	ok $contents =~ qr/\x67\x08\x17\x00\x67\x08\0\0\0\0\0\0\0\0\0\0\x02\x00\x01\xff\xff\xff\xff\x34\x12\x00\x00/,
		"File contents";
	
	unlink $test_file;
}

