use strict;
use warnings;

use Test::More tests => 15;

use String::SQLColumnName qw(fix_name fix_reserved);

# basics.
is(fix_name("Some name"),  'some_name');
is(fix_name("1st date"),   'first_date');
is(fix_name("2nd field"),  'second_field');

is(fix_reserved('group'),  'group_');
is(fix_reserved('sum'),  'sum_');
is(fix_reserved('count'),  'count_');
is(fix_reserved('distinct'),  'distinct_');

is(fix_name('one : two'),  'one_two');
is(fix_name('one, two, three'),  'one_two_three');
is(fix_name('one, two, three.'),  'one_two_three');
is(fix_name('one; two; three;;'),  'one_two_three');
is(fix_name('44 wives'),  'forty_four_wives');

is(fix_name('33ist'), 'thirty_threeist');
is(fix_name('33rd'), 'thirty_third');
is(fix_name('53rd and 1st'), 'fifty_third_and_first');

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
