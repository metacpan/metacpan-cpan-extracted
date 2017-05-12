
use strict;
use warnings;
use Test::More tests => 3;

use String::SQLColumnName qw(fix_name fix_reserved);

is(fix_name('group'),  'group_');
is(fix_name('12 months'),  'twelve_months');
is(fix_name('52 weeks total'),  'fifty_two_weeks_total');


# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
