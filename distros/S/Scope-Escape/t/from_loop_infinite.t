use warnings;
use strict;

use Test::More tests => 7;

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

sub dd($@) {
	my $aa = shift;
	my $i = 0;
	while(1) {
		last if $i++ == 3;
		$cont = current_escape_function;
		push @events, [ "dd0", $i, @_ ];
		push @events, [ "dd1", $aa->($i, @_), "z" ];
		push @events, [ "dd2", $i ];
	}
	return "dd3";
}

@events = (); $cont = undef;
is dd(\&aa, "t0", "0t"), "dd3";
is_deeply \@events, [
	[ "dd0", 1, "t0", "0t" ],
	[ "aa0", undef, 1, "t0", "0t" ],
	[ "dd0", 2, "t0", "0t" ],
	[ "aa0", undef, 2, "t0", "0t" ],
	[ "dd0", 3, "t0", "0t" ],
	[ "aa0", undef, 3, "t0", "0t" ],
];

@events = (); $cont = undef;
is dd(\&bb, "t0", "0t"), "dd3";
is_deeply \@events, [
	[ "dd0", 1, "t0", "0t" ],
	[ "bb0", undef, 1, "t0", "0t" ],
	[ "dd0", 2, "t0", "0t" ],
	[ "bb0", undef, 2, "t0", "0t" ],
	[ "dd0", 3, "t0", "0t" ],
	[ "bb0", undef, 3, "t0", "0t" ],
];

@events = (); $cont = undef;
is dd(\&cc, "t0", "0t"), "dd3";
is_deeply \@events, [
	[ "dd0", 1, "t0", "0t" ],
	[ "cc0", undef, 1, "t0", "0t" ],
	[ "dd0", 2, "t0", "0t" ],
	[ "cc0", undef, 2, "t0", "0t" ],
	[ "dd0", 3, "t0", "0t" ],
	[ "cc0", undef, 3, "t0", "0t" ],
];

1;
