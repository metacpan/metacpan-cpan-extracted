use warnings;
use strict;

use Test::More tests => 3;

BEGIN { use_ok "Scope::Cleanup", qw(establish_cleanup); }

my @events;

sub aa(@) {
	push @events, [ "aa0", @_ ];
	establish_cleanup sub { push @events, [ "bb0", @_ ] };
	push @events, [ "aa1" ];
	return "aa2";
	push @events, [ "aa3" ];
	"aa4";
}

@events = ();
push @events, [ "cc0" ];
push @events, [ "cc2", aa("cc1a", "cc1b") ];
is_deeply \@events, [
	[ "cc0" ],
	[ "aa0", "cc1a", "cc1b" ],
	[ "aa1" ],
	[ "bb0" ],
	[ "cc2", "aa2" ],
];

sub dd(@) {
	push @events, [ "dd0", @_ ];
	establish_cleanup sub { push @events, [ "ee0", @_ ] };
	push @events, [ "dd1" ];
	my $v = do {
		push @events, [ "dd2" ];
		establish_cleanup sub { push @events, [ "ee1", @_ ] };
		push @events, [ "dd3" ];
		return "dd4";
		push @events, [ "dd5" ];
		"dd6";
	};
	push @events, [ "dd7", $v ];
	"dd8";
}

@events = ();
push @events, [ "ff0" ];
push @events, [ "ff2", dd("ff1a", "ff1b") ];
is_deeply \@events, [
	[ "ff0" ],
	[ "dd0", "ff1a", "ff1b" ],
	[ "dd1" ],
	[ "dd2" ],
	[ "dd3" ],
	[ "ee1" ],
	[ "ee0" ],
	[ "ff2", "dd4" ],
];

1;
