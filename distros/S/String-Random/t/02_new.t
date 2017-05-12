use strict;
use warnings;

use Test::More tests => 2;

# 1: Make sure we can load the module
BEGIN { use_ok('String::Random'); }

# 2: Make sure we can create a new object
my $foo=new String::Random;
ok(defined($foo), "new()");

# vi: set ai et syntax=perl:
