#!perl

use strict;
use warnings;

use Test::More tests => 43;

use Spreadsheet::ReadGnumeric;

### Subroutines.

sub test_parse {
    my ($input, @options) = @_;

    my $parser = Spreadsheet::ReadGnumeric->new(@options);
    return $parser->parse($input);
}

### Main code.

# Test conversion routines.

# Note that this tests "carries" between digits and overflow into two and three
# digits; the numbers should increment seamlessly between adjacent octaves.
# (But this is not really base 26.)
for my $octave (qw(0 1 2 3 25 26 27 28)) {
    for my $case (qw(1 2 25 26)) {
	my $start = $case + 26 * $octave;
	my $alpha = Spreadsheet::ReadGnumeric::_encode_cell_name($start);
	my $end = Spreadsheet::ReadGnumeric::_decode_alpha($alpha);
	is($end, $start, "$start => '$alpha' => $end");
    }
}

# Test a simple spreadsheet.
my $data = test_parse('t/data/bank-statement.gnumeric');
use vars qw($test_1_simple_expected $test_1_simple_no_rc_expected);
use vars qw($test_1_simple_no_cells_expected);
do './t/data/test_1_expected.pl';
is_deeply($data, $test_1_simple_expected,
	  "t/data/bank-statement.gnumeric matches");

# Test it again uncompressed.
$data = test_parse('t/data/bank-statement.xml');
is_deeply($data, $test_1_simple_expected,
	  "t/data/bank-statement.xml matches");

# Test without row/column information.
$data = test_parse('t/data/bank-statement.xml', rc => 0, cells => 1);
is_deeply($data, $test_1_simple_no_rc_expected,
	  "t/data/bank-statement.xml matches");

# Test without cell information.
$data = test_parse('t/data/bank-statement.xml', rc => 1, cells => 0);
is_deeply($data, $test_1_simple_no_cells_expected,
	  "t/data/bank-statement.xml matches");

# Stream XML, compressed & not, without row/column information.
for my $file (qw(t/data/bank-statement.xml t/data/bank-statement.gnumeric)) {
    open(my $in, '<', $file) or die;
    $data = test_parse($in, rc => 0, cells => 1);
    is_deeply($data, $test_1_simple_no_rc_expected,
	      "$file from stream matches");
}

# Test from a literal string, compressed & not, without cell information.
for my $file (qw(t/data/bank-statement.xml t/data/bank-statement.gnumeric)) {
    my $string = do {
	local $/;
	open my $in, '<', $file;
	<$in>;
    };
    $data = test_parse($string, rc => 1, cells => 0);
    is_deeply($data, $test_1_simple_no_cells_expected,
	      "$file from string matches");
}

# Test the XML version with attributes.
my $statement_xml = 't/data/bank-statement.xml'; 
$data = test_parse($statement_xml, attr => 'keep', convert_colors => 0);
use vars qw($test_1_expected_attrs);
is(scalar(@{$data->[1]{style_regions}}), 49,
   "have 49 style regions in $statement_xml");
is_deeply([ @{$data->[1]{attr}[3]}[0 .. 10] ], $test_1_expected_attrs,
	  "$statement_xml attribute subset matches");
# Check that the color conversion default works.
$data = test_parse($statement_xml, attr => 1);
is($data->[1]{attr}[3][5]{bgcolor}, '#FFFFFF',
   "$statement_xml attribute [3][5] white BG was converted");
