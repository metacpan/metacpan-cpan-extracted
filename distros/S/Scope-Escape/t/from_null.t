use warnings;
use strict;

use Test::More tests => 6;

BEGIN { use_ok "Scope::Escape", qw(current_escape_function); }

BEGIN { Scope::Escape::_set_sanity_checking(1); }

my @events;
my $cont;

sub bb(@) {
	push @events, [ "bb0", Scope::Escape::Continuation::wantarray($cont),
			@_ ];
	push @events, [ "bb1", $cont->($b cmp $a), "z" ];
	push @events, [ "bb3" ];
	return $a cmp $b;
}

sub cc(@) {
	push @events, [ "cc0", Scope::Escape::Continuation::wantarray($cont),
			@_ ];
	push @events, [ "cc1", $cont->("cc2", $b cmp $a), "z" ];
	push @events, [ "cc4" ];
	return $a cmp $b;
}

sub ee($@) {
	my $aa = shift;
	push @events, [ "ee0", @_ ];
	push @events, [ "ee1", (sort {
		$cont = current_escape_function;
		push @events, [ "dd0", @_ ];
		push @events, [ "dd1", $aa->(@_), "z" ];
		push @events, [ "dd2" ];
		$a cmp $b;
	} qw(a b)), "z" ];
	push @events, [ "ee4" ];
	return "ee5";
}

@events = (); $cont = undef;
is ee(\&bb, "t0", "0t"), "ee5";
is_deeply \@events, [
	[ "ee0", "t0", "0t" ],
	[ "dd0", "t0", "0t" ],
	[ "bb0", !!0, "t0", "0t" ],
	[ "ee1", "b", "a", "z" ],
	[ "ee4" ],
];

@events = (); $cont = undef;
is ee(\&cc, "t0", "0t"), "ee5";
is_deeply \@events, [
	[ "ee0", "t0", "0t" ],
	[ "dd0", "t0", "0t" ],
	[ "cc0", !!0, "t0", "0t" ],
	[ "ee1", "b", "a", "z" ],
	[ "ee4" ],
];

is_deeply [
	sort {
		$cont = current_escape_function;
		$cont->($b cmp $a);
		$a cmp $b;
	} qw(o i y g h b e v n p r z w s x m c q j d k t a f l u)
], [
	qw(z y x w v u t s r q p o n m l k j i h g f e d c b a)
];

1;
