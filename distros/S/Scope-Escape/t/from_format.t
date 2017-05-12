use warnings;
use strict;

use Test::More tests => 7;

BEGIN { use_ok "Scope::Escape", qw(current_escape_function); }

BEGIN { Scope::Escape::_set_sanity_checking(1); }

my @events;
my($aa, $cont);

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

format STDOUT =
@<
($cont = current_escape_function), (push @events, ["dd0"]), (push @events, [ "dd1", $aa->("u0", "0u"), "z" ]), (push @events, ["dd2"]), (return "dd3")
.

sub ee($@) {
	$aa = shift;
	push @events, [ "ee0", @_ ];
	push @events, [ "ee1", write(), "z" ];
	push @events, [ "ee2", scalar(write()), "z" ];
	push @events, [ "ee3", do { write(); "v" }, "z" ];
	push @events, [ "ee4" ];
	return "ee5";
}

@events = (); $cont = undef;
is ee(\&aa, "t0", "0t"), "ee5";
is_deeply \@events, [
	[ "ee0", "t0", "0t" ],
	[ "dd0" ],
	[ "aa0", undef, "u0", "0u" ],
	[ "ee1", !!1, "z" ],
	[ "dd0" ],
	[ "aa0", undef, "u0", "0u" ],
	[ "ee2", !!1, "z" ],
	[ "dd0" ],
	[ "aa0", undef, "u0", "0u" ],
	[ "ee3", "v", "z" ],
	[ "ee4" ],
];

@events = (); $cont = undef;
is ee(\&bb, "t0", "0t"), "ee5";
is_deeply \@events, [
	[ "ee0", "t0", "0t" ],
	[ "dd0" ],
	[ "bb0", undef, "u0", "0u" ],
	[ "ee1", !!1, "z" ],
	[ "dd0" ],
	[ "bb0", undef, "u0", "0u" ],
	[ "ee2", !!1, "z" ],
	[ "dd0" ],
	[ "bb0", undef, "u0", "0u" ],
	[ "ee3", "v", "z" ],
	[ "ee4" ],
];

@events = (); $cont = undef;
is ee(\&cc, "t0", "0t"), "ee5";
is_deeply \@events, [
	[ "ee0", "t0", "0t" ],
	[ "dd0" ],
	[ "cc0", undef, "u0", "0u" ],
	[ "ee1", !!1, "z" ],
	[ "dd0" ],
	[ "cc0", undef, "u0", "0u" ],
	[ "ee2", !!1, "z" ],
	[ "dd0" ],
	[ "cc0", undef, "u0", "0u" ],
	[ "ee3", "v", "z" ],
	[ "ee4" ],
];

1;
