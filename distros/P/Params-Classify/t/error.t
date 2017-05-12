use warnings;
use strict;

use Test::More tests => 1 + (4*3 + 8 + 8*3 + 8*3)*6;

BEGIN { use_ok "Params::Classify", qw(
	is_ref check_ref
	is_blessed check_blessed
	is_strictly_blessed check_strictly_blessed
	is_able check_able
); }

foreach my $arg (
	undef,
	"foo",
	*STDOUT,
	bless({}, "main"),
	\1,
	{},
) {
	foreach my $type (undef, *STDOUT, {}) {
		eval { is_ref($arg, $type); };
		is $@, "reference type argument is not a string\n";
		eval { &is_ref($arg, $type); };
		is $@, "reference type argument is not a string\n";
		eval { check_ref($arg, $type); };
		is $@, "reference type argument is not a string\n";
		eval { &check_ref($arg, $type); };
		is $@, "reference type argument is not a string\n";
	}
	eval { is_ref($arg, "WIBBLE"); };
	is $@, "invalid reference type\n";
	eval { &is_ref($arg, "WIBBLE"); };
	is $@, "invalid reference type\n";
	eval { check_ref($arg, "WIBBLE"); };
	is $@, "invalid reference type\n";
	eval { &check_ref($arg, "WIBBLE"); };
	is $@, "invalid reference type\n";
	my $type = "WIBBLE";
	eval { is_ref($arg, $type); };
	is $@, "invalid reference type\n";
	eval { &is_ref($arg, $type); };
	is $@, "invalid reference type\n";
	eval { check_ref($arg, $type); };
	is $@, "invalid reference type\n";
	eval { &check_ref($arg, $type); };
	is $@, "invalid reference type\n";
	foreach my $class (undef, *STDOUT, {}) {
		eval { is_blessed($arg, $class); };
		is $@, "class argument is not a string\n";
		eval { &is_blessed($arg, $class); };
		is $@, "class argument is not a string\n";
		eval { check_blessed($arg, $class); };
		is $@, "class argument is not a string\n";
		eval { &check_blessed($arg, $class); };
		is $@, "class argument is not a string\n";
		eval { is_strictly_blessed($arg, $class); };
		is $@, "class argument is not a string\n";
		eval { &is_strictly_blessed($arg, $class); };
		is $@, "class argument is not a string\n";
		eval { check_strictly_blessed($arg, $class); };
		is $@, "class argument is not a string\n";
		eval { &check_strictly_blessed($arg, $class); };
		is $@, "class argument is not a string\n";
	}
	foreach my $meth (undef, *STDOUT, {}) {
		eval { is_able($arg, $meth); };
		is $@, "methods argument is not a string or array\n";
		eval { &is_able($arg, $meth); };
		is $@, "methods argument is not a string or array\n";
		eval { check_able($arg, $meth); };
		is $@, "methods argument is not a string or array\n";
		eval { &check_able($arg, $meth); };
		is $@, "methods argument is not a string or array\n";
		eval { is_able($arg, [$meth]); };
		is $@, "method name is not a string\n";
		eval { &is_able($arg, [$meth]); };
		is $@, "method name is not a string\n";
		eval { check_able($arg, [$meth]); };
		is $@, "method name is not a string\n";
		eval { &check_able($arg, [$meth]); };
		is $@, "method name is not a string\n";
	}
}

1;
