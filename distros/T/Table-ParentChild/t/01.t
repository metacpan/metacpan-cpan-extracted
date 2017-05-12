# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Table::ParentChild;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# ===== TEST 2
my $table = new Table::ParentChild();

if( defined $table ) {
	print "ok 2\n";
} else {
	print "not ok 2\n";
}

# ===== TEST 3
# See if the population works
my $data = [
	[ 0 => 10, 1 ],
	[ 1 => 11, 2 ],
	[ 2 => 12, 3 ],
	[ 3 => 13, 4 ],
	[ 1 => 12, 5 ],
	[ 4 => 15, 6 ],
];

$table = new Table::ParentChild( $data );
print "ok 3\n";

# ===== TEST 4
# See if the parent-lookup works

my $results;
my $test;

$results = $table->parent_lookup( 12 );
$test = join ", ", sort keys %$results;

if( $test eq "1, 2" ) {
	print "ok 4\n";

} else {
	print "not ok 4\n";
}

# ===== TEST 5
# See if the child-lookup works

$results = $table->child_lookup( 1 );
$test = join ", ", sort keys %$results;

if( $test eq "11, 12" ) {
	print "ok 5\n";

} else {
	print "not ok 5\n";
}


