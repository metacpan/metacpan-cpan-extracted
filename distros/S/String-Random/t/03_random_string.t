use strict;
use warnings;

use Test::More tests => 4;

# 1: Make sure we can load the module
BEGIN { use_ok('String::Random', ':all'); }

# 2: Make sure we can create a new object
my $foo=new String::Random;
ok(defined($foo), "new()");

# 3: Test function interface to randpattern()
my $abc=random_string("012", ['a'], ['b'], ['c']);
is($abc, 'abc', "random_string()");

# 4: Make sure the function didn't pollute $foo
ok(!defined($foo->{'0'}), "pollute object");

# vi: set ai et syntax=perl:
