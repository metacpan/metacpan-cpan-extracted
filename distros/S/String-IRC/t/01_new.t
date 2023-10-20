use strict;
use Test::More;

require String::IRC;
String::IRC->import;
note("new");
my $obj = new_ok("String::IRC");

# diag explain $obj

done_testing;
