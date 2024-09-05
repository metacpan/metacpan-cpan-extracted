#!/usr/bin/perl -w
use strict;
use warnings;
use String::Util ':all';
use Test::More;

# general purpose variable
my $val;

#------------------------------------------------------------------------------
# startswith non-regression
ok(startswith("0 sales done" , '0'),   "startswith '0'");
ok(startswith("Quick brown fox" , ''), "startswith empty string");
ok(startswith('0'),   "startswith '0', with \$_") for '0 sales done';
ok(!startswith('foo', undef), 'startswith no undef as substring');
ok(!startswith(undef, 'foo'), 'startswith no substring into undef');
ok(!startswith(), 'startswith no args nothing back');
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# endswith
ok(endswith('value is 5.0', '0'),   "endswith '0'");
ok(endswith('Quick brown fox', ''), "endswith word");
ok(endswith('0'),   "endswith '0', with \$_") for 'down to 0';
ok(!endswith('foo', undef), 'endswith no undef as substring');
ok(!endswith(undef, 'foo'), 'endswith no substring into undef');
ok(!endswith(), 'endswith no args nothing back');
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# contains
ok(contains('there are 0 left', '0'), "contains '0'");
ok(contains('Quick brown fox', ''),   "Contains word 2");
ok(contains('0'), "contains '0', with \$_") for 'with a 0 inside';
ok(!contains('foo', undef), 'contains no undef as substring');
ok(!contains(undef, 'foo'), 'contains no substring into undef');
ok(!contains(), 'contains no args nothing back');
#------------------------------------------------------------------------------


done_testing();
