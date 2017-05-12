use warnings;
use strict;

use Test::More tests => 2;

BEGIN { use_ok "Scope::Cleanup", qw(establish_cleanup); }

my @events;

sub ff { push @events, "ff0" }

format EE =
@<<
((push @events, "ee0"), (establish_cleanup \&ff), (push @events, "ee1"), "ee2")
.

sub gg {
	push @events, "gg0";
	write(EE);
	push @events, "gg1";
	"gg2";
}

@events = ();
open EE, ">", \(my $ee);
push @events, "hh0";
push @events, [ "hh1", gg() ];
close EE;
is_deeply \@events, [
	"hh0",
	"gg0",
	"ee0",
	"ee1",
	"ff0",
	"gg1",
	[ "hh1", "gg2" ],
];

1;
