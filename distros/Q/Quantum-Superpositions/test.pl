#!/usr/local/bin/perl -sw

print "1..42\n";

use Quantum::Superpositions UNARY => ['CORE::int'];

print "ok 1\n";

my $test = 2;
sub TEST
{
	my ($got, $expected, $true) = (@_,0);

	unless ("$got" eq "$expected") {
		print "\tline ", (caller)[2], "\n";
		print "\texpected: ";
		print $expected;
		print "\n";
		print "\tbut got:  ";
		print $got;
		print "\n";
		print  "not ";
	}
	print "ok ", $test++, "\n";

	unless (($got?1:0) == ($true?1:0)) {
		print "\tline ", (caller)[2], "\n";
		print "\texpected: ";
		print $true ? "true" : "false";
		print "\n";
		print "\tbut got:  ";
		print $got ? "true" : "false";
		print "\n";
		print  "not ";
	}
	print "ok ", $test++, "\n";

}

TEST all(1,2,3) != all(4,5,6), all(1,2,3), "true";

TEST all(1,2,3) < any(1,2,3), all();

TEST any(1,2,3) > all(1,2,3), any();

TEST all(1,2,3) < any(1,2,3,4), all(1,2,3), "true";

TEST any(1,2,3,4) > all(1,2,3), any(4), "true";

TEST all(1,2,3) != all(4,5,6), all(1,2,3), "true";

TEST all(1,2,3) < any(1,2,3), all();

TEST any(1,2,3) > all(1,2,3), any();

TEST all(2,3,4) > any(1,2,3), all(2,3,4), "true";

TEST any(1,2,3) < all(2,3,4), any(1), "true";

TEST all(2,3,4) > any(1,2,3,4), all(2,3,4), "true";

TEST all(1,2,3,4)*all(2,3,4) < any(10,11,12), all();

TEST all(1,2,3)*any(1,2,3), all(any(1,2,3),any(2,4,6),any(3,6,9));


sub factors {
	eigenstates (int($_[0] / any(2..$_[0]-1)) == ($_[0] / any(2..$_[0]-1)));
}

my $val = 60;
my @factors = factors($val);

foreach (@factors) {
	print "not " and last unless 60%$_ == 0
}
print "ok ", $test++, "\n";


use Quantum::Superpositions BINARY => ["CORE::index"];
	
TEST index(any("opts","tops","spot"),"o"), any(0,1,2), "true";

TEST index("stop",any("p","s")), any(0,3), "true";

TEST index(any("opts","tops","spot","stop"),any("o","p")), any(0,1,2,3), "true";


sub odder {
	grep($_%2, split "", $_[0]) > grep($_%2, split "", $_[1]);
}

use Quantum::Superpositions BINARY_LOGICAL => ['main::odder'];

TEST odder(any(1234,2468), 666), any(1234), "true";
TEST odder(any(1234,2468), 666), 1234, "true";

if ($] >= 5.006) {
	TEST any(sub{1 . shift()}, sub{pop() . 2})->("a", "z"), any("1a","z2"), "true";
	TEST all(sub{1 . shift()}, sub{pop() . 2})->("z", "a"), all("1z","a2");
}
else {
	TEST 1,1,1 for (1..2);
}
