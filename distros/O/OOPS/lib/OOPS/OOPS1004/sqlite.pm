
package OOPS::OOPS1004::sqlite;

our @ISA;

use strict;
use warnings;
use Carp qw(confess);

#
# When DBD::SQLite went from version 0.x to version 1.x it switched
# from SQLite 2.x to SQLite 3.x.   SQLite 2.x support moved to 
# DBD::SQLite2.  
#

if ($DBD::SQLite::VERSION < 1.00) {
	require OOPS::OOPS1004::sqlite2;
	import OOPS::OOPS1004::sqlite2;
	@ISA = qw(OOPS::OOPS1004::sqlite2);
} else {
	require OOPS::OOPS1004::sqlite_v3;
	import OOPS::OOPS1004::sqlite_v3;
	@ISA = qw(OOPS::OOPS1004::sqlite_v3);
}

1;
