use warnings;
use strict;

use Test::More tests => 7;

BEGIN { use_ok "Scope::Cleanup", qw(establish_cleanup); }

my @events;

sub aa(@) {
	push @events, [ "aa0", @_ ];
	establish_cleanup sub { push @events, [ "bb0", wantarray ] };
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
	[ "bb0", undef ],
	[ "cc2", "aa2" ],
];

@events = ();
push @events, [ "cc0" ];
push @events, [ "cc2", scalar(aa("cc1a", "cc1b")) ];
is_deeply \@events, [
	[ "cc0" ],
	[ "aa0", "cc1a", "cc1b" ],
	[ "aa1" ],
	[ "bb0", undef ],
	[ "cc2", "aa2" ],
];

@events = ();
push @events, [ "cc0" ];
push @events, [ "cc2", do { aa("cc1a", "cc1b"); "v" } ];
is_deeply \@events, [
	[ "cc0" ],
	[ "aa0", "cc1a", "cc1b" ],
	[ "aa1" ],
	[ "bb0", undef ],
	[ "cc2", "v" ],
];

@events = ();
sub {
	push @events, [ "dd0" ];
	push @events, [
		"dd1a",
		establish_cleanup(sub { push @events, [ "ee0" ] }),
		"dd1b",
	];
	push @events, [ "dd2" ];
}->();
is_deeply \@events, [
	[ "dd0" ],
	[ "dd1a", undef, "dd1b" ],
	[ "dd2" ],
	[ "ee0" ],
];

@events = ();
sub {
	push @events, [ "dd0" ];
	push @events, [
		"dd1a",
		scalar(establish_cleanup(sub { push @events, [ "ee0" ] })),
		"dd1b",
	];
	push @events, [ "dd2" ];
}->();
is_deeply \@events, [
	[ "dd0" ],
	[ "dd1a", undef, "dd1b" ],
	[ "dd2" ],
	[ "ee0" ],
];

@events = ();
sub {
	push @events, [ "dd0" ];
	push @events, [
		"dd1a",
		scalar(establish_cleanup(sub { push @events, [ "ee0" ] }), "v"),
		"dd1b",
	];
	push @events, [ "dd2" ];
}->();
is_deeply \@events, [
	[ "dd0" ],
	[ "dd1a", "v", "dd1b" ],
	[ "dd2" ],
	[ "ee0" ],
];

1;
