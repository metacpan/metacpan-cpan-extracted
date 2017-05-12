
# compatibility for SQLite 2.  Primarily for the hoary
# libdbd-sqlite-perl package which uses "SQLite2" as the driver name.

use strict;

package Tangram::Driver::SQLite2;

use Tangram::Driver::SQLite;
use vars qw(@ISA);
 @ISA = qw( Tangram::Driver::SQLite );

1;
