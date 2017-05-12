use warnings;
use strict;

use Test::More tests => 3;

BEGIN { use_ok "Scope::Cleanup", qw(establish_cleanup); }

my @events;

sub aa(@) {
	my $value = eval {
		push @events, [ "aa0", @_ ];
		establish_cleanup sub { push @events, [ "bb0", @_ ] };
		push @events, [ "aa1" ];
		my $zero = 0;
		push @events, [ "aa2", $zero/$zero ];
		push @events, [ "aa3" ];
		"aa4";
	};
	my $err = $@;
	$err =~ s/ at [^\n]*//;
	[ "aa5", $value, $err ];
}

@events = ();
push @events, [ "cc0" ];
push @events, [ "cc2", aa("cc1a", "cc1b") ];
is_deeply \@events, [
	[ "cc0" ],
	[ "aa0", "cc1a", "cc1b" ],
	[ "aa1" ],
	[ "bb0" ],
	[ "cc2", [ "aa5", undef, "Illegal division by zero\n" ] ],
];

sub dd(@) {
	my $value = eval {
		push @events, [ "dd0", @_ ];
		establish_cleanup sub { push @events, [ "ee0", @_ ] };
		push @events, [ "dd1" ];
		my $v = do {
			push @events, [ "dd2" ];
			establish_cleanup sub { push @events, [ "ee1", @_ ] };
			push @events, [ "dd3" ];
			my $zero = 0;
			push @events, [ "dd4", $zero/$zero ];
			push @events, [ "dd5" ];
			"dd6";
		};
		push @events, [ "dd7", $v ];
		"dd8";
	};
	my $err = $@;
	$err =~ s/ at [^\n]*//;
	[ "dd9", $value, $err ];
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
	[ "ff2", [ "dd9", undef, "Illegal division by zero\n" ] ],
];

1;
