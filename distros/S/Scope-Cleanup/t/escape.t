use warnings;
use strict;

BEGIN {
	eval { require Scope::Escape };
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all => "no Scope::Escape");
	}
	Scope::Escape->import(qw(current_escape_function));
}

use Test::More tests => 2;

BEGIN { use_ok "Scope::Cleanup", qw(establish_cleanup); }

my(@events, @value);

@events = ();
push @events, [ "aa0" ];
@value = do {
	my $escape = current_escape_function;
	push @events, [ "bb0" ];
	@value = sub {
		push @events, [ "cc0" ];
		@value = do {
			push @events, [ "dd0" ];
			establish_cleanup(sub {
				push @events, [ "ee0" ];
				$escape->("ee1a", "ee1b");
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
push @events, [ "aa1", [@value] ];
is_deeply \@events, [
	[ "aa0" ],
	[ "bb0" ],
	[ "cc0" ],
	[ "dd0" ],
	[ "dd1" ],
	[ "ee0" ],
	[ "aa1", [ "ee1a", "ee1b" ] ],
];

1;
