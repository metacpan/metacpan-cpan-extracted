use warnings;
use strict;

use Test::More tests => 1 + 2*8*11;

BEGIN {
	use_ok "Params::Classify", qw(
		scalar_class is_undef is_string
		is_number is_glob is_regexp is_ref is_blessed
	);
}

sub test_scalar_classification($$$$$$$$$) {
	my(undef, $class, $iu, $is, $in, $ig, $ix, $ir, $ib) = @_;
	is(scalar_class($_[0]), $class);
	is(&scalar_class($_[0]), $class);
	is(!!is_undef($_[0]), !!$iu);
	is(!!&is_undef($_[0]), !!$iu);
	is(!!is_string($_[0]), !!$is);
	is(!!&is_string($_[0]), !!$is);
	is(!!is_number($_[0]), !!$in);
	is(!!&is_number($_[0]), !!$in);
	is(!!is_glob($_[0]), !!$ig);
	is(!!&is_glob($_[0]), !!$ig);
	is(!!is_regexp($_[0]), !!$ix);
	is(!!&is_regexp($_[0]), !!$ix);
	is(!!is_ref($_[0]), !!$ir);
	is(!!&is_ref($_[0]), !!$ir);
	is(!!is_blessed($_[0]), !!$ib);
	is(!!&is_blessed($_[0]), !!$ib);
}

test_scalar_classification(undef,             "UNDEF",   1, 0, 0, 0, 0, 0, 0);
test_scalar_classification("",                "STRING",  0, 1, 0, 0, 0, 0, 0);
test_scalar_classification("abc",             "STRING",  0, 1, 0, 0, 0, 0, 0);
test_scalar_classification(123,               "STRING",  0, 1, 1, 0, 0, 0, 0);
test_scalar_classification(0,                 "STRING",  0, 1, 1, 0, 0, 0, 0);
test_scalar_classification("0 but true",      "STRING",  0, 1, 1, 0, 0, 0, 0);
test_scalar_classification("1ab",             "STRING",  0, 1, 0, 0, 0, 0, 0);
test_scalar_classification(*STDOUT,           "GLOB",    0, 0, 0, 1, 0, 0, 0);
SKIP: { skip "no first-class regexps", 2*8 unless "$]" >= 5.011;
test_scalar_classification(${qr/xyz/},        "REGEXP",  0, 0, 0, 0, 1, 0, 0);
}
test_scalar_classification({},                "REF",     0, 0, 0, 0, 0, 1, 0);
test_scalar_classification(bless({}, "main"), "BLESSED", 0, 0, 0, 0, 0, 0, 1);

1;
