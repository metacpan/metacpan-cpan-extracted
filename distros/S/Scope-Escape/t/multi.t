use warnings;
use strict;

BEGIN {
	if("$]" >= 5.019004 && "$]" < 5.022) {
		require Test::More;
		Test::More::plan(skip_all =>
			"this perl can't handle death during unwinding");
	}
	eval { require Scope::Cleanup; Scope::Cleanup->VERSION(0.003); };
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all => "no Scope::Cleanup");
	}
	*establish_cleanup = \&Scope::Cleanup::establish_cleanup;
}

use Test::More tests => 28;

BEGIN { use_ok "Scope::Escape", qw(current_escape_function); }

BEGIN { Scope::Escape::_set_sanity_checking(1); }

my($cont_out, $cont_in, @events);

$SIG{__DIE__} = sub {
	my($e) = @_;
	$e =~ s/ at [^\n]*//;
	die $e;
};

sub dotest($$$) {
	my($act_a, $act_b, $act_c) = @_;
	@events = ();
	my @value;
	@value = eval {
		@value = sub {
			push @events, ["aa0"];
			$cont_out = current_escape_function;
			establish_cleanup sub {
				push @events, ["cc0"];
				$$act_c->("cc1a", "cc1b") if $act_c;
			};
			push @events, ["aa1"];
			@value = sub {
				push @events, ["aa2"];
				$cont_in = current_escape_function;
				establish_cleanup sub {
					push @events, ["bb0"];
					$$act_b->("bb1a", "bb1b") if $act_b;
				};
				push @events, ["aa3"];
				$$act_a->("aa4a", "aa4b") if $act_a;
				("aa5a", "aa5b");
			}->();
			push @events, ["aa6", [@value]];
			("aa7a", "aa7b");
		}->();
		push @events, ["aa8", [@value]];
		("aa9a", "aa9b");
	};
	push @events, ["aa10", [@value], $@];
	return \@events;
}

#
# (Relatively) simple cases: all attempted transfers are valid, and there
# are no attempted transfers to scopes already being unwound to.
#

is_deeply dotest(undef, undef, undef), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["aa6", ["aa5a", "aa5b"]],
	["cc0"],
	["aa8", ["aa7a", "aa7b"]],
	["aa10", ["aa9a", "aa9b"], ""],
];

is_deeply dotest(\$cont_in, undef, undef), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["aa6", ["aa4a", "aa4b"]],
	["cc0"],
	["aa8", ["aa7a", "aa7b"]],
	["aa10", ["aa9a", "aa9b"], ""],
];

is_deeply dotest(\$cont_out, undef, undef), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["cc0"],
	["aa8", ["aa4a", "aa4b"]],
	["aa10", ["aa9a", "aa9b"], ""],
];

is_deeply dotest(undef, \$cont_out, undef), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["cc0"],
	["aa8", ["bb1a", "bb1b"]],
	["aa10", ["aa9a", "aa9b"], ""],
];

is_deeply dotest(\$cont_in, \$cont_out, undef), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["cc0"],
	["aa8", ["bb1a", "bb1b"]],
	["aa10", ["aa9a", "aa9b"], ""],
];

#
# Valid transfers to scopes already being unwound to for escape.
#

is_deeply dotest(\$cont_in, \$cont_in, undef), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["aa6", ["bb1a", "bb1b"]],
	["cc0"],
	["aa8", ["aa7a", "aa7b"]],
	["aa10", ["aa9a", "aa9b"], ""],
];

is_deeply dotest(\$cont_out, \$cont_out, undef), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["cc0"],
	["aa8", ["bb1a", "bb1b"]],
	["aa10", ["aa9a", "aa9b"], ""],
];

is_deeply dotest(\$cont_out, undef, \$cont_out), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["cc0"],
	["aa8", ["cc1a", "cc1b"]],
	["aa10", ["aa9a", "aa9b"], ""],
];

is_deeply dotest(undef, \$cont_out, \$cont_out), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["cc0"],
	["aa8", ["cc1a", "cc1b"]],
	["aa10", ["aa9a", "aa9b"], ""],
];

is_deeply dotest(\$cont_in, \$cont_out, \$cont_out), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["cc0"],
	["aa8", ["cc1a", "cc1b"]],
	["aa10", ["aa9a", "aa9b"], ""],
];

is_deeply dotest(\$cont_out, \$cont_out, \$cont_out), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["cc0"],
	["aa8", ["cc1a", "cc1b"]],
	["aa10", ["aa9a", "aa9b"], ""],
];

#
# Transfers invalid due to non-escape unwinding, not expected to be detected.
#

SKIP: { skip "transfers invalid due to non-escape unwinding", 5;

is_deeply dotest(undef, \$cont_in, undef), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["aa6", ["bb1a", "bb1b"]],
	["cc0"],
	["aa8", ["aa7a", "aa7b"]],
	["aa10", ["aa9a", "aa9b"], ""],
];

is_deeply dotest(undef, undef, \$cont_out), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["aa6", ["aa5a", "aa5b"]],
	["cc0"],
	["aa8", ["cc1a", "cc1b"]],
	["aa10", ["aa9a", "aa9b"], ""],
];

is_deeply dotest(\$cont_in, undef, \$cont_out), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["aa6", ["aa4a", "aa4b"]],
	["cc0"],
	["aa8", ["cc1a", "cc1b"]],
	["aa10", ["aa9a", "aa9b"], ""],
];

is_deeply dotest(undef, \$cont_in, \$cont_out), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["aa6", ["bb1a", "bb1b"]],
	["cc0"],
	["aa8", ["cc1a", "cc1b"]],
	["aa10", ["aa9a", "aa9b"], ""],
];

is_deeply dotest(\$cont_in, \$cont_in, \$cont_out), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["aa6", ["bb1a", "bb1b"]],
	["cc0"],
	["aa8", ["cc1a", "cc1b"]],
	["aa10", ["aa9a", "aa9b"], ""],
];

}

#
# Fully invalid transfers (invalid under Common Lisp semantics).
#

SKIP: { skip "fully invalid transfers", 11;

is_deeply dotest(\$cont_out, \$cont_in, undef), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["cc0"],
	["aa10", [], "attempt to use invalid continuation\n"],
];

is_deeply dotest(undef, undef, \$cont_in), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["aa6", ["aa5a", "aa5b"]],
	["cc0"],
	["aa10", [], "attempt to use invalid continuation\n"],
];

is_deeply dotest(\$cont_in, undef, \$cont_in), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["aa6", ["aa4a", "aa4b"]],
	["cc0"],
	["aa10", [], "attempt to use invalid continuation\n"],
];

is_deeply dotest(\$cont_out, undef, \$cont_in), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["cc0"],
	["aa10", [], "attempt to use invalid continuation\n"],
];

is_deeply dotest(undef, \$cont_in, \$cont_in), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["aa6", ["bb1a", "bb1b"]],
	["cc0"],
	["aa10", [], "attempt to use invalid continuation\n"],
];

is_deeply dotest(\$cont_in, \$cont_in, \$cont_in), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["aa6", ["bb1a", "bb1b"]],
	["cc0"],
	["aa10", [], "attempt to use invalid continuation\n"],
];

is_deeply dotest(\$cont_out, \$cont_in, \$cont_in), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["cc0"],
	["aa10", [], "attempt to use invalid continuation\n"],
];

is_deeply dotest(undef, \$cont_out, \$cont_in), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["cc0"],
	["aa10", [], "attempt to use invalid continuation\n"],
];

is_deeply dotest(\$cont_in, \$cont_out, \$cont_in), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["cc0"],
	["aa10", [], "attempt to use invalid continuation\n"],
];

is_deeply dotest(\$cont_out, \$cont_out, \$cont_in), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["cc0"],
	["aa10", [], "attempt to use invalid continuation\n"],
];

is_deeply dotest(\$cont_out, \$cont_in, \$cont_out), [
	["aa0"],
	["aa1"],
	["aa2"],
	["aa3"],
	["bb0"],
	["cc0"],
	["aa10", [], "attempt to use invalid continuation\n"],
];

}

1;
