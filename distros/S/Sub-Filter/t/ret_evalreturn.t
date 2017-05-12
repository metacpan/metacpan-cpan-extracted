use warnings;
use strict;

use Test::More tests => 7;

BEGIN { use_ok "Sub::Filter", qw(mutate_sub_filter_return); }

sub t0 {
	if($_[0] == 0) {
		return "<a>";
	} elsif($_[0] == 1) {
		my $x = eval { return "b" };
		return "<$x>";
	} else {
		return "<c>";
	}
}

sub f0 { "F".$_[0]."F" }

is t0(0), "<a>";
is t0(1), "<b>";
is t0(2), "<c>";
mutate_sub_filter_return(\&t0, \&f0);
is t0(0), "F<a>F";
is t0(1), "F<b>F";
is t0(2), "F<c>F";

1;
