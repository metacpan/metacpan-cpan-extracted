use warnings;
use strict;

use Test::More tests => 2;

BEGIN { use_ok "Scope::Cleanup", qw(establish_cleanup); }

my @events;

@events = ();
push @events, ["a"];
sub {
	push @events, ["b"];
	my $c = "c";
	establish_cleanup sub { push @events, ["d", $c]; };
	push @events, ["e", $c];
	sub {
		push @events, ["f", $c];
		my $g = "g";
		establish_cleanup sub { push @events, ["h", $c, $g]; };
		push @events, ["i", $c, $g];
	}->();
	push @events, ["j", $c];
}->();
push @events, ["k"];
is_deeply \@events, [
	["a"],
	["b"],
	["e", "c"],
	["f", "c"],
	["i", "c", "g"],
	["h", "c", "g"],
	["j", "c"],
	["d", "c"],
	["k"],
];

1;
