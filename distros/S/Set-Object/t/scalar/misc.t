use Set::Object;

print "1..2\n";

{
	# Malcolm Purvis <malcolm.purvis@alcatel.com.au>
	my $s1 = Set::Object->new("A");
	my $s1_again = Set::Object->new("A");
	my $s2 = $s1->union($s1_again);
	my $s3 = Set::Object->new("C");
	my $s4 = $s2->difference($s3);
	print "not " unless $s4 eq "Set::Object(A)";
	print "ok 1\n";
}

{
	# Malcolm Purvis <malcolm.purvis@alcatel.com.au>
	my $s1 = Set::Object->new(("A", "B"));
	my $s1_again = Set::Object->new(("A", "B"));
	my $s2 = $s1->union($s1_again);  
	my $s3 = Set::Object->new("C");
	my $s4 = $s2->difference($s3);
	print "not " unless $s4 eq "Set::Object(A B)";
	print "ok 2\n";
}
