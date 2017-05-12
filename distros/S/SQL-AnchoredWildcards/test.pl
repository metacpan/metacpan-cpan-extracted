# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use SQL::AnchoredWildcards;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $NewSearchText = "";		# converted search text
my $OldSearchText = "";		# unconverted search text



# ------ 2: test search with no wildcards
# ------    make it unanchored at beginning and end
$OldSearchText = "dms";
$NewSearchText = sql_anchor_wildcards($OldSearchText);
print "ok 2\n" if ($NewSearchText eq '%dms%');


# ------ 3: test with initial SQL '%'
$OldSearchText = "%dms";
$NewSearchText = sql_anchor_wildcards($OldSearchText);
print "ok 3\n" if ($NewSearchText eq '%dms%');


# ------ 4: test with ending SQL '%'
$OldSearchText = "dms%";
$NewSearchText = sql_anchor_wildcards($OldSearchText);
print "ok 4\n" if ($NewSearchText eq '%dms%');


# ------ 5: test with initial and ending SQL '%'
$OldSearchText = "%dms%";
$NewSearchText = sql_anchor_wildcards($OldSearchText);
print "ok 5\n" if ($NewSearchText eq '%dms%');


# ------ 6: test with initial '^'
$OldSearchText = "^dms";
$NewSearchText = sql_anchor_wildcards($OldSearchText);
print "ok 6\n" if ($NewSearchText eq 'dms%');


# ------ 7: test with initial '^' and ending SQL '%'
$OldSearchText = "^dms%";
$NewSearchText = sql_anchor_wildcards($OldSearchText);
print "ok 7\n" if ($NewSearchText eq 'dms%');


# ------ 8: test with ending escaped '$'
$OldSearchText = "dms\$";
$NewSearchText = sql_anchor_wildcards($OldSearchText);
print "ok 8\n" if ($NewSearchText eq 'dms%');


# ------ 9: test with initial '%' and ending '$'
$OldSearchText = "%dms\$";
$NewSearchText = sql_anchor_wildcards($OldSearchText);
print "ok 9\n" if ($NewSearchText eq '%dms');


# ------ 10: test with initial '%' and ending '$'
$OldSearchText = "^dms\$";
$NewSearchText = sql_anchor_wildcards($OldSearchText);
print "ok 10\n" if ($NewSearchText eq 'dms');

$OldSearchText = "\\^dms\$";
$NewSearchText = sql_anchor_wildcards($OldSearchText);
print "ok 11\n" if ($NewSearchText eq '%^dms');

$OldSearchText = "^dms\\\$";
$NewSearchText = sql_anchor_wildcards($OldSearchText);
print "ok 12\n" if ($NewSearchText eq 'dms$%');

$OldSearchText = "^d%ms\$";
$NewSearchText = sql_anchor_wildcards($OldSearchText);
print "ok 13\n" if ($NewSearchText eq 'd%ms');

$OldSearchText = "^d^ms\$";
$NewSearchText = sql_anchor_wildcards($OldSearchText);
print "ok 14\n" if ($NewSearchText eq 'd^ms');

$OldSearchText = "^d\$ms\$";
$NewSearchText = sql_anchor_wildcards($OldSearchText);
print "ok 15\n" if ($NewSearchText eq 'd$ms');

$OldSearchText = "\\^d%ms\$";
$NewSearchText = sql_anchor_wildcards($OldSearchText);
print "ok 16\n" if ($NewSearchText eq '%^d%ms');

$OldSearchText = "\\^d^ms\$";
$NewSearchText = sql_anchor_wildcards($OldSearchText);
print "ok 17\n" if ($NewSearchText eq '%^d^ms');

$OldSearchText = "^d\$ms\\\$";
$NewSearchText = sql_anchor_wildcards($OldSearchText);
print "ok 18\n" if ($NewSearchText eq 'd$ms$%');

$OldSearchText = "^d%ms\\\$";
$NewSearchText = sql_anchor_wildcards($OldSearchText);
print "ok 19\n" if ($NewSearchText eq 'd%ms$%');

$OldSearchText = "\\^d\$ms\\\$";
$NewSearchText = sql_anchor_wildcards($OldSearchText);
print "ok 20\n" if ($NewSearchText eq '^d$ms$%');


