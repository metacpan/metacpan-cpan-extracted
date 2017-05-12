use warnings;
use strict;

use Test::More tests => 1 + 5*2*6;

BEGIN { use_ok "Sub::Filter", qw(mutate_sub_filter_return); }

sub f0 { "f" }
our $context;
sub record_context {
	$context = wantarray ? "array" :
			defined(wantarray) ? "scalar" : "void";
	return "a";
}

sub test_p0 {
	record_context();
}
sub test_p1 {
	(record_context());
}
sub test_p2 {
	return record_context();
}
sub test_p3 {
	return (record_context());
}
our $true = 1;
our $junk;
sub test_p4 {
	my $z = 1;
	if($true) {
		my $y = 2;
		$junk = $z + $y;
		return record_context();
	} else {
		$junk = $z + 123;
	}
	$junk++;
}
sub test_p5 {
	my $z = 1;
	if($true) {
		my $y = 2;
		$junk = $z + $y;
		return (record_context());
	} else {
		$junk = $z + 123;
	}
	$junk++;
}

foreach my $func (
	\&test_p0,
	\&test_p1,
	\&test_p2,
	\&test_p3,
	\&test_p4,
	\&test_p5,
) {
	$context = undef;
	is_deeply [$func->()], ["a"];
	is $context, "array";
	$context = undef;
	is_deeply scalar($func->()), "a";
	is $context, "scalar";
	$context = undef;
	$func->();
	is $context, "void";
	mutate_sub_filter_return($func, \&f0);
	$context = undef;
	is_deeply [$func->()], ["f"];
	is $context, "array";
	$context = undef;
	is_deeply scalar($func->()), "f";
	is $context, "scalar";
	$context = undef;
	$func->();
	is $context, "void";
}

1;
