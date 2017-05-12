# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Sort::Fields;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$^W = 1;

my $n = 2;

sub array_compare {
	my($a1, $a2) = @_;
	return 0 unless $#$a1 == $#$a2;
	for (my $i = 0; $i <= $#$a1; $i++) {
		return 0 unless $$a1[$i] eq $$a2[$i];
	}
	1;
}
sub test {
	print array_compare(@_) ?  "ok $n\n" : "not ok $n\n";
	$n++;
}

sub test_msg {
	my ($warn, $die) = ('', '');
	local $SIG{__WARN__} = sub { $warn = shift };
	local $SIG{__DIE__} = sub { $die = shift };
	my $code = shift;
	eval $code;
	$warn =~ s/ at (?!.*\bat\b)[\w\W]*$//;
	$die =~ s/ at (?!.*\bat\b)[\w\W]*$//;
	if ($warn eq $_[0] and $die eq $_[1]) {
		print "ok $n\n";
	} else {
		print "not ok $n\n";
		print "code: $code";
		print " warn: $warn\n" if $warn;
		print " die: $die\n" if $die;
	}
	$n++;
}

@data = <DATA>;

# test warnings, errors

for (qw(fieldsort stable_fieldsort make_fieldsort make_stable_fieldsort)) {
	test_msg qq{
		$_();
	}, "", "$_ requires argument(s)";
	test_msg qq{
		$_(1);
	}, "", "$_ field specifiers must be in anon array";
	test_msg qq{
		$_([]);
	}, "", "$_ must have at least one field specifier";
	test_msg qq{
		$_(['x']);
	}, "", "improperly formatted $_ column specifier 'x'";
	test_msg qq{
		$_(q/(/, ['1n']);
	}, "", "probable regexp error in $_ arg: /(/
/(/: unmatched () in regexp";
}
for (qw(fieldsort stable_fieldsort)) {
	test_msg qq{
		scalar $_([1], qw(a b c));
	}, "fieldsort called in scalar or void context", "";
}	


# ascending numeric
test(
	[fieldsort(['1n'], @data)],
	[map {$_->[0]} sort {$a->[1]<=>$b->[1]} map {[$_, split /\s+/]} @data]
);

# ascending alpha
test(
	[fieldsort([2], @data)],
	[map {$_->[0]} sort {$a->[2]cmp$b->[2]} map {[$_, split /\s+/]} @data]
);

# ascending numeric
test(
	[fieldsort(['3n'], @data)],
	[map {$_->[0]} sort {$a->[3]<=>$b->[3]} map {[$_, split /\s+/]} @data]
);

# ascending numeric
test(
	[fieldsort(['4n'], @data)],
	[map {$_->[0]} sort {$a->[4]<=>$b->[4]} map {[$_, split /\s+/]} @data]
);

# descending numeric
test(
	[fieldsort(['-1n'], @data)],
	[map {$_->[0]} sort {$b->[1]<=>$a->[1]} map {[$_, split /\s+/]} @data]
);

# descending alpha
test(
	[fieldsort([-2], @data)],
	[map {$_->[0]} sort {$b->[2]cmp$a->[2]} map {[$_, split /\s+/]} @data]
);

# descending numeric
test(
	[fieldsort(['-3n'], @data)],
	[map {$_->[0]} sort {$b->[3]<=>$a->[3]} map {[$_, split /\s+/]} @data]
);

# descending numeric
test(
	[fieldsort(['-4n'], @data)],
	[map {$_->[0]} sort {$b->[4]<=>$a->[4]} map {[$_, split /\s+/]} @data]
);

# ascending alpha, then ascending numeric
test(
	[fieldsort([1, '4n'], @data)],
	[map {$_->[0]} sort {$a->[1]cmp$b->[1] or $a->[4]<=>$b->[4]} map {[$_, split /\s+/]} @data]
);

# ascending alpha, then descending numeric
test(
	[fieldsort([1, '-4n'], @data)],
	[map {$_->[0]} sort {$a->[1]cmp$b->[1] or $b->[4]<=>$a->[4]} map {[$_, split /\s+/]} @data]
);

# ascending alpha, then ascending alpha
test(
	[fieldsort([2, 0], @data)],
	[map {$_->[0]} sort {$a->[2]cmp$b->[2] or $a->[0]cmp$b->[0]} map {[$_, split /\s+/]} @data]
);

# ascending alpha, then descending numeric
test(
	[fieldsort([2, '-0'], @data)],
	[map {$_->[0]} sort {$a->[2]cmp$b->[2] or $b->[0]cmp$a->[0]} map {[$_, split /\s+/]} @data]
);

# stable, ascending numeric
my $i = 0;
test(
	[fieldsort(['-', '1n'], @data)],
	[map {$_->[0]} sort {$a->[2]<=>$b->[2] or $a->[1]<=>$b->[1]} map {[$_, $i++, split /\s+/]} @data]
);

# stable, ascending numeric
$i = 0;
test(
	[stable_fieldsort(['1n'], @data)],
	[map {$_->[0]} sort {$a->[2]<=>$b->[2] or $a->[1]<=>$b->[1]} map {[$_, $i++, split /\s+/]} @data]
);

# stable, ascending numeric, then descending alphabetic
$i = 0;
test(
	[stable_fieldsort(['1n', -2], @data)],
	[map {$_->[0]} sort {$a->[2]<=>$b->[2] or $b->[3]cmp$a->[3] or $a->[1]<=>$b->[1]} map {[$_, $i++, split /\s+/]} @data]
);

$i = 0;

__END__
0 a 1  -4.5
0 a 2  -2.5
0 b 3  1e2
1 b 4  123456
1 b 5  1e3
1 b 6  2e5
0 b 7  .00001
0 a 8  .00002
1 a 9  -.234e2
1 b 10  1e-1
0 a 12  1e-2
0 a 13  .123
0 a 14  .234
0 b 15  1.234
0 a 16  12345.6789
1 a 17  12345.6788
1 a 18  12345.6787
1 a 19  -2222
0 b 20  -2223
0 b 21  -1e1
1 b 22  -1e-1
1 b 23  -2e2
0 b 24  -2e-2
0 b 25  -3e3
0 b 26  -3e-3
0 b 27  123345.123234
0 a 28  123345.123235
0 a 29  123345.123233
0 a 30  -4.6
0 b 31  -4.7
0 b 32  -4.8
1 b 33  -4.5e1
1 a 34  1.23
1 a 35  2.345
1 b 36  345.456
1 a 37  45678.67567
0 b 38  23423422.34234234
1 a 39  123124123
