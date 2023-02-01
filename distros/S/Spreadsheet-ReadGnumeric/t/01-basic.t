#!perl

use strict;
use warnings;

use Test::More tests => 8;

use Spreadsheet::ReadGnumeric;

### Subroutines.

sub test_parse {
    my ($input, @options) = @_;

    my $parser = Spreadsheet::ReadGnumeric->new(@options);
    return $parser->parse($input);
}

### Main code.

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
