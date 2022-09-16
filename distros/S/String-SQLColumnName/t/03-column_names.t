
use strict;
use warnings;
use Test::More tests => 1;

use String::SQLColumnName;

my @cols_in = (
	       '1st unit',
	       '2nd unit',
	       'repeated',
	       'repeated',
	      );

my @cols_out = ("first_unit", "second_unit", "repeated_01", "repeated_02");

is_deeply([ sql_column_names(@cols_in) ], \@cols_out);

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
