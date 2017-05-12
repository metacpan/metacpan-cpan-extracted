use Set::Scalar;

print "1..3\n";

{
	# Malcolm Purvis <malcolm.purvis@alcatel.com.au>
	my $s1 = Set::Scalar->new("A");
	my $s1_again = Set::Scalar->new("A");
	my $s2 = $s1->union($s1_again);
	my $s3 = Set::Scalar->new("C");
	my $s4 = $s2->difference($s3);
	print "not " unless $s4 eq "(A)";
	print "ok 1\n";
}

{
	# Malcolm Purvis <malcolm.purvis@alcatel.com.au>
	my $s1 = Set::Scalar->new(("A", "B"));
	my $s1_again = Set::Scalar->new(("A", "B"));
	my $s2 = $s1->union($s1_again);  
	my $s3 = Set::Scalar->new("C");
	my $s4 = $s2->difference($s3);
	print "not " unless $s4 eq "(A B)";
	print "ok 2\n";
}

{
	# Josh@allDucky.com
	use Set::Scalar;
	my $x = new Set::Scalar( [] );
	my @m = $x->members;
	print "not " unless $m[0] =~ /^ARRAY\(0x[0-9a-fA-F]+\)$/;
	print "ok 3\n";
}
