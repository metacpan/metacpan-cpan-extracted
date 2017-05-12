use warnings;
use strict;

use Test::More tests => 9;

BEGIN { use_ok "Scope::Escape", qw(current_escape_function); }

BEGIN { Scope::Escape::_set_sanity_checking(1); }

my @events;
my $cont;

sub aa(@) {
	push @events, [ "aa0", Scope::Escape::Continuation::wantarray($cont),
			@_ ];
	push @events, [ "aa1", $cont->(), "z" ];
	push @events, [ "aa2" ];
	return "aa3";
}

sub bb(@) {
	push @events, [ "bb0", Scope::Escape::Continuation::wantarray($cont),
			@_ ];
	push @events, [ "bb1", $cont->("bb2"), "z" ];
	push @events, [ "bb3" ];
	return "bb4";
}

sub cc(@) {
	push @events, [ "cc0", Scope::Escape::Continuation::wantarray($cont),
			@_ ];
	push @events, [ "cc1", $cont->("cc2", "cc3"), "z" ];
	push @events, [ "cc4" ];
	return "cc5";
}

sub ee($@) {
	my $aa = shift;
	push @events, [ "ee0", @_ ];
	push @events, [ "ee1", do {
		$cont = current_escape_function;
		push @events, [ "dd0", @_ ];
		push @events, [ "dd1", $aa->(@_), "z" ];
		push @events, [ "dd2" ];
		return "dd3";
	}, "z" ];
	push @events, [ "ee2", scalar(do {
		$cont = current_escape_function;
		push @events, [ "dd0", @_ ];
		push @events, [ "dd1", $aa->(@_), "z" ];
		push @events, [ "dd2" ];
		return "dd3";
	}), "z" ];
	push @events, [ "ee3", do { do {
		$cont = current_escape_function;
		push @events, [ "dd0", @_ ];
		push @events, [ "dd1", $aa->(@_), "z" ];
		push @events, [ "dd2" ];
		return "dd3";
	}; "v" }, "z" ];
	push @events, [ "ee4" ];
	return "ee5";
}

@events = (); $cont = undef;
is ee(\&aa, "t0", "0t"), "ee5";
is_deeply \@events, [
	[ "ee0", "t0", "0t" ],
	[ "dd0", "t0", "0t" ],
	[ "aa0", !!1, "t0", "0t" ],
	[ "ee1", "z" ],
	[ "dd0", "t0", "0t" ],
	[ "aa0", !!0, "t0", "0t" ],
	[ "ee2", undef, "z" ],
	[ "dd0", "t0", "0t" ],
	[ "aa0", undef, "t0", "0t" ],
	[ "ee3", "v", "z" ],
	[ "ee4" ],
];

@events = (); $cont = undef;
is ee(\&bb, "t0", "0t"), "ee5";
is_deeply \@events, [
	[ "ee0", "t0", "0t" ],
	[ "dd0", "t0", "0t" ],
	[ "bb0", !!1, "t0", "0t" ],
	[ "ee1", "bb2", "z" ],
	[ "dd0", "t0", "0t" ],
	[ "bb0", !!0, "t0", "0t" ],
	[ "ee2", "bb2", "z" ],
	[ "dd0", "t0", "0t" ],
	[ "bb0", undef, "t0", "0t" ],
	[ "ee3", "v", "z" ],
	[ "ee4" ],
];

@events = (); $cont = undef;
is ee(\&cc, "t0", "0t"), "ee5";
is_deeply \@events, [
	[ "ee0", "t0", "0t" ],
	[ "dd0", "t0", "0t" ],
	[ "cc0", !!1, "t0", "0t" ],
	[ "ee1", "cc2", "cc3", "z" ],
	[ "dd0", "t0", "0t" ],
	[ "cc0", !!0, "t0", "0t" ],
	[ "ee2", "cc3", "z" ],
	[ "dd0", "t0", "0t" ],
	[ "cc0", undef, "t0", "0t" ],
	[ "ee3", "v", "z" ],
	[ "ee4" ],
];

is_deeply [ "a", do { "b", current_escape_function->("c", "d"), "e" }, "f" ],
	[ "a", "c", "d", "f" ];

@events = ();
push @events, "a";
push(@events, "b"), current_escape_function->("c"), push(@events, "d") while 1;
push @events, "e";
is_deeply \@events, [ "a", "b", "e" ];

1;
