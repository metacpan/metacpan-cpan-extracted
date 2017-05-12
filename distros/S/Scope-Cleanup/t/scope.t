use warnings;
use strict;

use Test::More tests => 3;

BEGIN { use_ok "Scope::Cleanup", qw(establish_cleanup); }

my @events;

sub aa(@) {
	push @events, [ "aa0", @_ ];
	establish_cleanup sub { push @events, [ "bb0", @_ ] }
		if 1;
	establish_cleanup sub { push @events, [ "bb1", @_ ] }
		if 0;
	establish_cleanup sub { push @events, [ "bb2", @_ ] }
		if 1;
	push @events, [ "aa1" ];
	"aa2";
}

@events = ();
push @events, [ "cc0" ];
push @events, [ "cc2", aa("cc1a", "cc1b") ];
is_deeply \@events, [
	[ "cc0" ],
	[ "aa0", "cc1a", "cc1b" ],
	[ "aa1" ],
	[ "bb2" ],
	[ "bb0" ],
	[ "cc2", "aa2" ],
];

sub dd(@) {
	push @events, [ "dd0", @_ ];
	do { establish_cleanup sub { push @events, [ "ee0", @_ ] } }
		if 1;
	do { establish_cleanup sub { push @events, [ "ee1", @_ ] } }
		if 0;
	do { establish_cleanup sub { push @events, [ "ee2", @_ ] } }
		if 1;
	push @events, [ "dd1" ];
	"dd2";
}

@events = ();
push @events, [ "ff0" ];
push @events, [ "ff2", dd("ff1a", "ff1b") ];
is_deeply \@events, [
	[ "ff0" ],
	[ "dd0", "ff1a", "ff1b" ],
	[ "ee0" ],
	[ "ee2" ],
	[ "dd1" ],
	[ "ff2", "dd2" ],
];

1;
