use warnings;
use strict;

use Test::More tests => 1 + 2*28*21;

BEGIN {
	use_ok "Params::Classify", map { ("is_$_", "check_$_") } qw(
		undef string number glob regexp
		ref blessed strictly_blessed able
	);
}

format foo =
.

my $foo = "";

@B::ISA = qw(A);

sub A::flange { }

foreach(
	undef,
	"",
	"abc",
	123,
	0,
	"0 but true",
	"1ab",
	*STDOUT,
	${qr/xyz/},
	\"",
	\\"",
	\pos($foo),
	[],
	{},
	\&is,
	do {
		my $format = *foo{FORMAT};
		defined($format) ? $format : undef;
	},
	bless({}, "main"),
	bless({}, "ARRAY"),
	bless({}, "HASH"),
	bless({}, "A"),
	bless({}, "B"),
) {
	eval { check_undef($_); };
	is $@, is_undef($_) ? "" : "argument is not undefined\n";
	eval { &check_undef($_); };
	is $@, is_undef($_) ? "" : "argument is not undefined\n";
	eval { check_string($_); };
	is $@, is_string($_) ? "" : "argument is not a string\n";
	eval { &check_string($_); };
	is $@, is_string($_) ? "" : "argument is not a string\n";
	eval { check_number($_); };
	is $@, is_number($_) ? "" : "argument is not a number\n";
	eval { &check_number($_); };
	is $@, is_number($_) ? "" : "argument is not a number\n";
	eval { check_glob($_); };
	is $@, is_glob($_) ? "" : "argument is not a typeglob\n";
	eval { &check_glob($_); };
	is $@, is_glob($_) ? "" : "argument is not a typeglob\n";
	eval { check_regexp($_); };
	is $@, is_regexp($_) ? "" : "argument is not a regexp\n";
	eval { &check_regexp($_); };
	is $@, is_regexp($_) ? "" : "argument is not a regexp\n";
	eval { check_ref($_); };
	is $@, is_ref($_) ? "" :
		"argument is not a reference to plain object\n";
	eval { &check_ref($_); };
	is $@, is_ref($_) ? "" :
		"argument is not a reference to plain object\n";
	eval { check_ref($_, "SCALAR"); };
	is $@, is_ref($_, "SCALAR") ? "" :
		"argument is not a reference to plain scalar\n";
	eval { &check_ref($_, "SCALAR"); };
	is $@, is_ref($_, "SCALAR") ? "" :
		"argument is not a reference to plain scalar\n";
	eval { check_ref($_, "ARRAY"); };
	is $@, is_ref($_, "ARRAY") ? "" :
		"argument is not a reference to plain array\n";
	eval { &check_ref($_, "ARRAY"); };
	is $@, is_ref($_, "ARRAY") ? "" :
		"argument is not a reference to plain array\n";
	eval { check_ref($_, "HASH"); };
	is $@, is_ref($_, "HASH") ? "" :
		"argument is not a reference to plain hash\n";
	eval { &check_ref($_, "HASH"); };
	is $@, is_ref($_, "HASH") ? "" :
		"argument is not a reference to plain hash\n";
	eval { check_ref($_, "CODE"); };
	is $@, is_ref($_, "CODE") ? "" :
		"argument is not a reference to plain code\n";
	eval { &check_ref($_, "CODE"); };
	is $@, is_ref($_, "CODE") ? "" :
		"argument is not a reference to plain code\n";
	eval { check_ref($_, "FORMAT"); };
	is $@, is_ref($_, "FORMAT") ? "" :
		"argument is not a reference to plain format\n";
	eval { &check_ref($_, "FORMAT"); };
	is $@, is_ref($_, "FORMAT") ? "" :
		"argument is not a reference to plain format\n";
	eval { check_ref($_, "IO"); };
	is $@, is_ref($_, "IO") ? "" :
		"argument is not a reference to plain io\n";
	eval { &check_ref($_, "IO"); };
	is $@, is_ref($_, "IO") ? "" :
		"argument is not a reference to plain io\n";
	foreach my $type (qw(SCALAR ARRAY HASH CODE FORMAT IO)) {
		eval { check_ref($_, $type); };
		is $@, is_ref($_, $type) ? "" :
			"argument is not a reference to plain @{[lc($type)]}\n";
		eval { &check_ref($_, $type); };
		is $@, is_ref($_, $type) ? "" :
			"argument is not a reference to plain @{[lc($type)]}\n";
	}
	eval { check_blessed($_); };
	is $@, is_blessed($_) ? "" :
		"argument is not a reference to blessed object\n";
	eval { &check_blessed($_); };
	is $@, is_blessed($_) ? "" :
		"argument is not a reference to blessed object\n";
	eval { check_blessed($_, "A"); };
	is $@, is_blessed($_, "A") ? "" :
		"argument is not a reference to blessed A\n";
	eval { &check_blessed($_, "A"); };
	is $@, is_blessed($_, "A") ? "" :
		"argument is not a reference to blessed A\n";
	eval { check_blessed($_, "B"); };
	is $@, is_blessed($_, "B") ? "" :
		"argument is not a reference to blessed B\n";
	eval { &check_blessed($_, "B"); };
	is $@, is_blessed($_, "B") ? "" :
		"argument is not a reference to blessed B\n";
	eval { check_strictly_blessed($_); };
	is $@, is_blessed($_) ? "" :
		"argument is not a reference to blessed object\n";
	eval { &check_strictly_blessed($_); };
	is $@, is_blessed($_) ? "" :
		"argument is not a reference to blessed object\n";
	eval { check_strictly_blessed($_, "A"); };
	is $@, is_strictly_blessed($_, "A") ? "" :
		"argument is not a reference to strictly blessed A\n";
	eval { &check_strictly_blessed($_, "A"); };
	is $@, is_strictly_blessed($_, "A") ? "" :
		"argument is not a reference to strictly blessed A\n";
	eval { check_strictly_blessed($_, "B"); };
	is $@, is_strictly_blessed($_, "B") ? "" :
		"argument is not a reference to strictly blessed B\n";
	eval { &check_strictly_blessed($_, "B"); };
	is $@, is_strictly_blessed($_, "B") ? "" :
		"argument is not a reference to strictly blessed B\n";
	eval { check_able($_); };
	is $@, is_able($_) ? "" :
		"argument is not a reference to blessed object\n";
	eval { &check_able($_); };
	is $@, is_able($_) ? "" :
		"argument is not a reference to blessed object\n";
	eval { check_able($_, []); };
	is $@, is_able($_, []) ? "" :
		"argument is not able to perform at all\n";
	eval { &check_able($_, []); };
	is $@, is_able($_, []) ? "" :
		"argument is not able to perform at all\n";
	eval { check_able($_, "flange"); };
	is $@, is_able($_, "flange") ? "" :
		"argument is not able to perform method \"flange\"\n";
	eval { &check_able($_, "flange"); };
	is $@, is_able($_, "flange") ? "" :
		"argument is not able to perform method \"flange\"\n";
	eval { check_able($_, ["flange","can"]); };
	is $@, is_able($_, ["flange","can"]) ? "" :
		"argument is not able to perform method \"flange\"\n";
	eval { &check_able($_, ["flange","can"]); };
	is $@, is_able($_, ["flange","can"]) ? "" :
		"argument is not able to perform method \"flange\"\n";
}

1;
