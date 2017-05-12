use warnings;
use strict;

use Test::More tests => 5;

BEGIN { use_ok "Scope::Escape", qw(current_escape_function); }

BEGIN { Scope::Escape::_set_sanity_checking(1); }

our($cont, @value, @events);

$SIG{__DIE__} = sub {
	my($e) = @_;
	$e =~ s/ at [^\n]*//;
	die $e;
};

$cont = undef; @events = ();
push @events, ["a0"];
@value = eval {
	push @events, ["b0"];
	@value = sub {
		push @events, ["c0"];
		$cont = current_escape_function;
		push @events, ["c1"];
		push @events, ["c2",
			Scope::Escape::Continuation::is_accessible($cont)];
		@value = $cont->("c2a", "c2b");
		push @events, ["c3", [@value]];
		("c4a", "c4b");
	}->();
	push @events, ["b1", [@value]];
	("b2a", "b2b");
};
push @events, ["a1", [@value], $@];
is_deeply \@events, [
	["a0"],
	["b0"],
	["c0"],
	["c1"],
	["c2", !!1],
	["b1", ["c2a", "c2b"]],
	["a1", ["b2a", "b2b"], ""],
];

$cont = undef; @events = ();
push @events, ["a0"];
@value = eval {
	push @events, ["b0"];
	@value = sub {
		push @events, ["c0"];
		$cont = current_escape_function;
		push @events, ["c1"];
		@value = do {
			local $ENV{FOO};
			push @events, ["c2",
				Scope::Escape::Continuation::is_accessible(
					$cont)];
			$cont->("c2a", "c2b");
		};
		push @events, ["c3", [@value]];
		("c4a", "c4b");
	}->();
	push @events, ["b1", [@value]];
	("b2a", "b2b");
};
push @events, ["a1", [@value], $@];
is_deeply \@events, [
	["a0"],
	["b0"],
	["c0"],
	["c1"],
	["c2", !!1],
	["b1", ["c2a", "c2b"]],
	["a1", ["b2a", "b2b"], ""],
];

$cont = undef; @events = ();
push @events, ["a0"];
@value = eval {
	push @events, ["b0"];
	@value = sub {
		push @events, ["c0"];
		$cont = current_escape_function;
		push @events, ["c1"];
		@value = eval {
			push @events, ["c2",
				Scope::Escape::Continuation::is_accessible(
					$cont)];
			$cont->("c2a", "c2b");
		};
		push @events, ["c3", [@value], $@];
		("c4a", "c4b");
	}->();
	push @events, ["b1", [@value]];
	("b2a", "b2b");
};
push @events, ["a1", [@value], $@];
is_deeply \@events, [
	["a0"],
	["b0"],
	["c0"],
	["c1"],
	["c2", !!0],
	["c3", [], "attempt to transfer past impervious stack frame\n"],
	["b1", ["c4a", "c4b"]],
	["a1", ["b2a", "b2b"], ""],
];

$cont = undef; @events = ();
push @events, ["a0"];
@value = eval {
	push @events, ["b0"];
	@value = sub {
		push @events, ["c0"];
		$cont = current_escape_function;
		push @events, ["c1"];
		@value = require("t/eval_barrier_req.pl");
		push @events, ["c3", [@value]];
		("c4a", "c4b");
	}->();
	push @events, ["b1", [@value]];
	("b2a", "b2b");
};
push @events, ["a1", [@value], $@];
is_deeply \@events, [
	["a0"],
	["b0"],
	["c0"],
	["c1"],
	["c2", !!0],
	["a1", [], "attempt to transfer past impervious stack frame\n".
			"Compilation failed in require\n"],
];

1;
