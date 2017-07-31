use warnings;
use strict;

use Test::More tests => 7;

BEGIN { use_ok "Scope::Escape", qw(current_escape_function); }

BEGIN { Scope::Escape::_set_sanity_checking(1); }

our @events;
our($aa, $cont);

$SIG{__DIE__} = sub {
	my($e) = @_;
	$e =~ s/ at [^\n]*//;
	die $e;
};
unshift @INC, "./t/lib";

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

sub ee($@) {
	$aa = shift;
	push @events, [ "ee0", @_ ];

	delete $INC{"t/from_eval_dofile_dd.pl"};
	$@ = "wibble\n";
	push @events, [ "ee1", require("t/from_eval_dofile_dd.pl"), "z", $@ ];
	delete $INC{"t/from_eval_dofile_dd.pl"};
	$@ = "wibble\n";
	push @events, [ "ee2",
		scalar(require("t/from_eval_dofile_dd.pl")),
	"z", $@ ];
	delete $INC{"t/from_eval_dofile_dd.pl"};
	$@ = "wibble\n";
	push @events, [ "ee3",
		do { require("t/from_eval_dofile_dd.pl"); "v" },
	"z", $@ ];
	push @events, [ "ee4" ];
	return "ee5";
}

sub eev($@) {
	$aa = shift;
	push @events, [ "ee0", @_ ];

	delete $INC{"t/from_eval_dofile_dd.pl"};
	$@ = "wibble\n";
	push @events, [ "ee1",
		eval { require("t/from_eval_dofile_dd.pl") },
	"z", $@ ];
	delete $INC{"t/from_eval_dofile_dd.pl"};
	$@ = "wibble\n";
	push @events, [ "ee2",
		eval { scalar(require("t/from_eval_dofile_dd.pl")) },
	"z", $@ ];
	delete $INC{"t/from_eval_dofile_dd.pl"};
	$@ = "wibble\n";
	push @events, [ "ee3",
		eval { do { require("t/from_eval_dofile_dd.pl"); "v" } },
	"z", $@ ];
	push @events, [ "ee4" ];
	return "ee5";
}

@events = (); $cont = undef;
is eev(\&aa, "t0", "0t"), "ee5";
is_deeply \@events, [
	[ "ee0", "t0", "0t" ],
	[ "dd0", "t0", "0t" ],
	[ "aa0", !!0, "t0", "0t" ],
	[ "ee1", "z","t/from_eval_dofile_dd.pl did not return a true value\n"],
	[ "dd0", "t0", "0t" ],
	[ "aa0", !!0, "t0", "0t" ],
	[ "ee2", "z","t/from_eval_dofile_dd.pl did not return a true value\n"],
	[ "dd0", "t0", "0t" ],
	[ "aa0", !!0, "t0", "0t" ],
	[ "ee3", "z","t/from_eval_dofile_dd.pl did not return a true value\n"],
	[ "ee4" ],
];

@events = (); $cont = undef;
is ee(\&bb, "t0", "0t"), "ee5";
is_deeply \@events, [
	[ "ee0", "t0", "0t" ],
	[ "dd0", "t0", "0t" ],
	[ "bb0", !!0, "t0", "0t" ],
	[ "ee1", "bb2", "z", "" ],
	[ "dd0", "t0", "0t" ],
	[ "bb0", !!0, "t0", "0t" ],
	[ "ee2", "bb2", "z", "" ],
	[ "dd0", "t0", "0t" ],
	[ "bb0", !!0, "t0", "0t" ],
	[ "ee3", "v", "z", "" ],
	[ "ee4" ],
];

@events = (); $cont = undef;
is ee(\&cc, "t0", "0t"), "ee5";
is_deeply \@events, [
	[ "ee0", "t0", "0t" ],
	[ "dd0", "t0", "0t" ],
	[ "cc0", !!0, "t0", "0t" ],
	[ "ee1", "cc3", "z", "" ],
	[ "dd0", "t0", "0t" ],
	[ "cc0", !!0, "t0", "0t" ],
	[ "ee2", "cc3", "z", "" ],
	[ "dd0", "t0", "0t" ],
	[ "cc0", !!0, "t0", "0t" ],
	[ "ee3", "v", "z", "" ],
	[ "ee4" ],
];

1;
