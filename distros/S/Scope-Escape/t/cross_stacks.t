use warnings;
use strict;

use Test::More tests => 7;

BEGIN { use_ok "Scope::Escape", qw(current_escape_function); }

BEGIN { Scope::Escape::_set_sanity_checking(1); }

my @events;
my $cont;

sub aa(@) {
	push @events, [ "aa0", @_ ];
	push @events, [ "aa1", $cont->(), "z" ];
	push @events, [ "aa2" ];
	return "aa3";
}

sub bb(@) {
	push @events, [ "bb0", @_ ];
	push @events, [ "bb1", $cont->("bb2"), "z" ];
	push @events, [ "bb3" ];
	return "bb4";
}

sub cc(@) {
	push @events, [ "cc0", @_ ];
	push @events, [ "cc1", $cont->("cc2", "cc3"), "z" ];
	push @events, [ "cc4" ];
	return "cc5";
}

sub dd($@) {
	my $aa = shift;
	$cont = current_escape_function;
	push @events, [ "dd0", @_ ];
	push @events, [ "dd1", (sort { $aa->(@_); 0 } 0, 0), "z" ];
	push @events, [ "dd2" ];
	return "dd3";
}

sub ee($@) {
	my $aa = shift;
	push @events, [ "ee0", @_ ];
	push @events, [ "ee1", dd($aa, @_), "z" ];
	push @events, [ "ee2", scalar(dd($aa, @_)), "z" ];
	push @events, [ "ee3", do { dd($aa, @_); "v" }, "z" ];
	push @events, [ "ee4" ];
	return "ee5";
}

@events = (); $cont = undef;
is ee(\&aa, "t0", "0t"), "ee5";
is_deeply \@events, [
	[ "ee0", "t0", "0t" ],
	[ "dd0", "t0", "0t" ],
	[ "aa0", "t0", "0t" ],
	[ "ee1", "z" ],
	[ "dd0", "t0", "0t" ],
	[ "aa0", "t0", "0t" ],
	[ "ee2", undef, "z" ],
	[ "dd0", "t0", "0t" ],
	[ "aa0", "t0", "0t" ],
	[ "ee3", "v", "z" ],
	[ "ee4" ],
];

@events = (); $cont = undef;
is ee(\&bb, "t0", "0t"), "ee5";
is_deeply \@events, [
	[ "ee0", "t0", "0t" ],
	[ "dd0", "t0", "0t" ],
	[ "bb0", "t0", "0t" ],
	[ "ee1", "bb2", "z" ],
	[ "dd0", "t0", "0t" ],
	[ "bb0", "t0", "0t" ],
	[ "ee2", "bb2", "z" ],
	[ "dd0", "t0", "0t" ],
	[ "bb0", "t0", "0t" ],
	[ "ee3", "v", "z" ],
	[ "ee4" ],
];

@events = (); $cont = undef;
is ee(\&cc, "t0", "0t"), "ee5";
is_deeply \@events, [
	[ "ee0", "t0", "0t" ],
	[ "dd0", "t0", "0t" ],
	[ "cc0", "t0", "0t" ],
	[ "ee1", "cc2", "cc3", "z" ],
	[ "dd0", "t0", "0t" ],
	[ "cc0", "t0", "0t" ],
	[ "ee2", "cc3", "z" ],
	[ "dd0", "t0", "0t" ],
	[ "cc0", "t0", "0t" ],
	[ "ee3", "v", "z" ],
	[ "ee4" ],
];

1;
