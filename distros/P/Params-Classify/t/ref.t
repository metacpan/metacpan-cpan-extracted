use warnings;
use strict;

use Test::More tests => 1 + 2*14*12;

BEGIN { use_ok "Params::Classify", qw(is_ref ref_type); }

format foo =
.

my $foo = "";

sub test_ref_type($$) {
	my($scalar, $reftype) = @_;
	is(ref_type($scalar), $reftype);
	is(&ref_type($scalar), $reftype);
	is(!!is_ref($scalar), !!$reftype);
	is(!!&is_ref($scalar), !!$reftype);
	$reftype = "" if !defined($reftype);
	is(!!is_ref($scalar, "SCALAR"), "SCALAR" eq $reftype);
	is(!!&is_ref($scalar, "SCALAR"), "SCALAR" eq $reftype);
	is(!!is_ref($scalar, "ARRAY"), "ARRAY" eq $reftype);
	is(!!&is_ref($scalar, "ARRAY"), "ARRAY" eq $reftype);
	is(!!is_ref($scalar, "HASH"), "HASH" eq $reftype);
	is(!!&is_ref($scalar, "HASH"), "HASH" eq $reftype);
	is(!!is_ref($scalar, "CODE"), "CODE" eq $reftype);
	is(!!&is_ref($scalar, "CODE"), "CODE" eq $reftype);
	is(!!is_ref($scalar, "FORMAT"), "FORMAT" eq $reftype);
	is(!!&is_ref($scalar, "FORMAT"), "FORMAT" eq $reftype);
	is(!!is_ref($scalar, "IO"), "IO" eq $reftype);
	is(!!&is_ref($scalar, "IO"), "IO" eq $reftype);
	foreach my $type (qw(SCALAR ARRAY HASH CODE FORMAT IO)) {
		is(!!is_ref($scalar, $type), $type eq $reftype);
		is(!!&is_ref($scalar, $type), $type eq $reftype);
	}
}

test_ref_type(undef, undef);
test_ref_type("foo", undef);
test_ref_type(123, undef);
test_ref_type(*STDOUT, undef);
test_ref_type(bless({}, "main"), undef);

test_ref_type(\1, "SCALAR");
test_ref_type(\\1, "SCALAR");
test_ref_type(\pos($foo), "SCALAR");
test_ref_type([], "ARRAY");
test_ref_type({}, "HASH");
test_ref_type(\&is, "CODE");

SKIP: {
	my $format = *foo{FORMAT};
	skip "this Perl doesn't do *foo{FORMAT}", 2*14 unless defined $format;
	test_ref_type($format, "FORMAT");
}

1;
