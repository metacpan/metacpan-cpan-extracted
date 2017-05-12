use warnings;
use strict;

use Test::More tests => 2;

BEGIN { use_ok "Scope::Cleanup", qw(establish_cleanup); }

my(@events, @value);

@events = ();
push @events, [ "aa0" ];
@value = eval {
	push @events, [ "bb0" ];
	@value = sub {
		push @events, [ "cc0" ];
		@value = do {
			push @events, [ "dd0" ];
			establish_cleanup(sub {
				push @events, [ "ee0" ];
				die "ee1\n";
				push @events, [ "ee2" ];
			});
			push @events, [ "dd1" ];
			("dd2a", "dd2b");
		};
		push @events, [ "cc1", [@value] ];
		("cc2a", "cc2b");
	}->();
	push @events, [ "bb1", [@value] ];
	("bb2a", "bb2b");
};
push @events, [ "aa1", [@value], $@ ];
is_deeply \@events, [
	[ "aa0" ],
	[ "bb0" ],
	[ "cc0" ],
	[ "dd0" ],
	[ "dd1" ],
	[ "ee0" ],
	[ "aa1", [],  "ee1\n" ],
];

1;
