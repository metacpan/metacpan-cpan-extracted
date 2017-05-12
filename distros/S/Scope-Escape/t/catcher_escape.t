use warnings;
use strict;

use Test::More tests => 11;

BEGIN { use_ok "Scope::Escape", qw(current_escape_function); }

BEGIN { Scope::Escape::_set_sanity_checking(1); }

my(@events, $cont, @value, @sort, $junkcont);

@events = (); $cont = undef; @value = (); @sort = ();
@value = sub {
	$cont = current_escape_function;
	push @events, ["aa0"];
	@sort = sort {
		push @events, ["aa1"];
		$cont->("aa2");
		push @events, ["aa3"];
		0;
	} 0, 0;
	push @events, ["aa4", [@sort]];
	("aa5a", "aa5b");
}->();
push @events, ["aa6", [@value]];
is_deeply \@events, [
	["aa0"],
	["aa1"],
	["aa6", ["aa2"]],
];

@events = (); $cont = undef; @value = (); @sort = ();
@value = sub {
	$cont = current_escape_function;
	push @events, ["aa0"];
	@sort = sort {
		push @events, ["aa1"];
		@value = sub {
			$cont = current_escape_function;
			$cont->("aa2");
			("x");
		}->();
		push @events, ["aa3", [@value]];
		0;
	} 0, 0;
	push @events, ["aa4", [@sort]];
	("aa5a", "aa5b");
}->();
push @events, ["aa6", [@value]];
is_deeply \@events, [
	["aa0"],
	["aa1"],
	["aa3", ["aa2"]],
	["aa4", [0,0]],
	["aa6", ["aa5a", "aa5b"]],
];

@events = (); $cont = undef; @value = (); @sort = ();
@value = sub {
	$cont = current_escape_function;
	push @events, ["aa0"];
	@sort = sort {
		eval { };
		push @events, ["aa1"];
		$cont->("aa2");
		push @events, ["aa3"];
		0;
	} 0, 0;
	push @events, ["aa4", [@sort]];
	("aa5a", "aa5b");
}->();
push @events, ["aa6", [@value]];
is_deeply \@events, [
	["aa0"],
	["aa1"],
	["aa6", ["aa2"]],
];

@events = (); $cont = undef; @value = (); @sort = ();
@value = sub {
	$cont = current_escape_function;
	push @events, ["aa0"];
	@sort = sort {
		eval { };
		push @events, ["aa1"];
		@value = sub {
			$cont = current_escape_function;
			$cont->("aa2");
			("x");
		}->();
		push @events, ["aa3", [@value]];
		0;
	} 0, 0;
	push @events, ["aa4", [@sort]];
	("aa5a", "aa5b");
}->();
push @events, ["aa6", [@value]];
is_deeply \@events, [
	["aa0"],
	["aa1"],
	["aa3", ["aa2"]],
	["aa4", [0,0]],
	["aa6", ["aa5a", "aa5b"]],
];

@events = (); $cont = undef; @value = (); @sort = ();
@value = sub {
	$cont = current_escape_function;
	push @events, ["aa0"];
	@sort = sort {
		$junkcont = current_escape_function;
		push @events, ["aa1"];
		$cont->("aa2");
		push @events, ["aa3"];
		0;
	} 0, 0;
	push @events, ["aa4", [@sort]];
	("aa5a", "aa5b");
}->();
push @events, ["aa6", [@value]];
is_deeply \@events, [
	["aa0"],
	["aa1"],
	["aa6", ["aa2"]],
];

@events = (); $cont = undef; @value = (); @sort = ();
@value = sub {
	$cont = current_escape_function;
	push @events, ["aa0"];
	@sort = sort {
		$junkcont = current_escape_function;
		push @events, ["aa1"];
		@value = sub {
			$cont = current_escape_function;
			$cont->("aa2");
			("x");
		}->();
		push @events, ["aa3", [@value]];
		0;
	} 0, 0;
	push @events, ["aa4", [@sort]];
	("aa5a", "aa5b");
}->();
push @events, ["aa6", [@value]];
is_deeply \@events, [
	["aa0"],
	["aa1"],
	["aa3", ["aa2"]],
	["aa4", [0,0]],
	["aa6", ["aa5a", "aa5b"]],
];

@events = (); $cont = undef; @value = (); @sort = ();
@value = sub {
	$cont = current_escape_function;
	push @events, ["aa0"];
	@sort = sort {
		eval { };
		$junkcont = current_escape_function;
		push @events, ["aa1"];
		$cont->("aa2");
		push @events, ["aa3"];
		0;
	} 0, 0;
	push @events, ["aa4", [@sort]];
	("aa5a", "aa5b");
}->();
push @events, ["aa6", [@value]];
is_deeply \@events, [
	["aa0"],
	["aa1"],
	["aa6", ["aa2"]],
];

@events = (); $cont = undef; @value = (); @sort = ();
@value = sub {
	$cont = current_escape_function;
	push @events, ["aa0"];
	@sort = sort {
		eval { };
		$junkcont = current_escape_function;
		push @events, ["aa1"];
		@value = sub {
			$cont = current_escape_function;
			$cont->("aa2");
			("x");
		}->();
		push @events, ["aa3", [@value]];
		0;
	} 0, 0;
	push @events, ["aa4", [@sort]];
	("aa5a", "aa5b");
}->();
push @events, ["aa6", [@value]];
is_deeply \@events, [
	["aa0"],
	["aa1"],
	["aa3", ["aa2"]],
	["aa4", [0,0]],
	["aa6", ["aa5a", "aa5b"]],
];

@events = (); $cont = undef; @value = (); @sort = ();
@value = sub {
	$cont = current_escape_function;
	push @events, ["aa0"];
	@sort = sort {
		$junkcont = current_escape_function;
		eval { };
		push @events, ["aa1"];
		$cont->("aa2");
		push @events, ["aa3"];
		0;
	} 0, 0;
	push @events, ["aa4", [@sort]];
	("aa5a", "aa5b");
}->();
push @events, ["aa6", [@value]];
is_deeply \@events, [
	["aa0"],
	["aa1"],
	["aa6", ["aa2"]],
];

@events = (); $cont = undef; @value = (); @sort = ();
@value = sub {
	$cont = current_escape_function;
	push @events, ["aa0"];
	@sort = sort {
		$junkcont = current_escape_function;
		eval { };
		push @events, ["aa1"];
		@value = sub {
			$cont = current_escape_function;
			$cont->("aa2");
			("x");
		}->();
		push @events, ["aa3", [@value]];
		0;
	} 0, 0;
	push @events, ["aa4", [@sort]];
	("aa5a", "aa5b");
}->();
push @events, ["aa6", [@value]];
is_deeply \@events, [
	["aa0"],
	["aa1"],
	["aa3", ["aa2"]],
	["aa4", [0,0]],
	["aa6", ["aa5a", "aa5b"]],
];

1;
