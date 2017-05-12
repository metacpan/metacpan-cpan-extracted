use warnings;
use strict;

use Test::More tests => 53;

use Scope::Escape::Sugar qw(block return_from);

my(@events, @value);

@events = ();
@value = sub {
	push @events, [ "aa0" ];
	block b;
	push @events, [ "aa1" ];
	return_from(b "aa2a", "aa2b");
	push @events, [ "aa3" ];
	("aa4a", "aa4b");
}->();
push @events, [ "bb0", [@value] ];
is_deeply \@events, [
	[ "aa0" ],
	[ "aa1" ],
	[ "bb0", [ "aa2a", "aa2b" ] ],
];

@events = ();
@value = sub {
	push @events, [ "aa0" ];
	block b {
		push @events, [ "aa1" ];
		return_from(b "aa2a", "aa2b");
		push @events, [ "aa3" ];
		("aa4a", "aa4b");
	}
}->();
push @events, [ "bb0", [@value] ];
is_deeply \@events, [
	[ "aa0" ],
	[ "aa1" ],
	[ "bb0", [ "aa2a", "aa2b" ] ],
];

@events = ();
@value = sub {
	push @events, [ "aa0" ];
	@value = block(b {
		push @events, [ "aa1" ];
		return_from(b "aa2a", "aa2b");
		push @events, [ "aa3" ];
		("aa4a", "aa4b");
	});
	push @events, [ "aa5", [@value] ];
	("aa6a", "aa6b");
}->();
push @events, [ "bb0", [@value] ];
is_deeply \@events, [
	[ "aa0" ],
	[ "aa1" ],
	[ "aa5", [ "aa2a", "aa2b" ] ],
	[ "bb0", [ "aa6a", "aa6b" ] ],
];

@events = ();
sub cc($) {
	block b;
	push @events, [ "cc0" ];
	$_[0]->();
	push @events, [ "cc1" ];
}
@value = block(b {
	push @events, [ "dd0" ];
	push @events, [ "dd1a", cc(sub {
		push @events, [ "ee0" ];
		return_from(b "ee1a", "ee1b");
		push @events, [ "ee2" ];
	}), "dd1b" ];
	push @events, [ "dd2" ];
	("dd3a", "dd3b");
});
push @events, [ "ff0", [@value] ];
is_deeply \@events, [
	[ "dd0" ],
	[ "cc0" ],
	[ "ee0" ],
	[ "ff0", [ "ee1a", "ee1b" ] ],
];

is block(a {
	100 + block(a {
		return_from(a 10);
		20;
	});
}), 110;

is block(a {
	100 + block(b {
		return_from(a 10);
		20;
	});
}), 10;

is block(a {
	1000 + block(a {
		100 + block(a {
			return_from(a 10);
			20;
		});
	});
}), 1110;

is block(a {
	1000 + block(a {
		100 + block(b {
			return_from(a 10);
			20;
		});
	});
}), 1010;

is block(a {
	1000 + block(b {
		100 + block(a {
			return_from(a 10);
			20;
		});
	});
}), 1110;

is block(b {
	1000 + block(a {
		100 + block(a {
			return_from(a 10);
			20;
		});
	});
}), 1110;

is block(a {
	1000 + block(b {
		100 + block(b {
			return_from(a 10);
			20;
		});
	});
}), 10;

my $decl = "use Scope::Escape::Sugar qw(block return_from);\n";

is eval($decl.q{ block a { return_from(a 30); 40; } }), 30;
is $@, "";

is eval($decl.q{ block b { return_from(a 30); 40; } }), undef;
like $@, qr/\Ano block named "a" is visible/;

is eval($decl.q{ block a { return_from a 30; 40; } }), 30;
is $@, "";

is eval($decl.q{ my $x=10; block a { $x=20; return_from a; $x=30; } $x }), 20;
is $@, "";

is eval($decl.q{ my $x=10; block a { $x=20; return_from(a); $x=30; } $x }), 20;
is $@, "";

foreach(
	q{ block foo; },
	q{ block foo ; },
	q{ { block foo; } },
	q{ { block foo } },
	q{ {block foo} },
	q{block foo},
	q{ block foo{} },
	q{ block foo {} },
	q{ block foo{ } },
	q{ block(foo{}); },
	q{ block (foo{}); },
	q{ block( foo{}); },
	q{ block(foo {}); },
	q{ block(foo{ }); },
	q{ block(foo{} ); },
	q{ block(foo{}) ; },
	q{ block foo; my $y = 1; },
	q{ block foo {} my $y = 1; },
	q{ block(foo {}); my $y = 1; },
	q{ block foo; 1 + return_from(foo 2); },
	q{ block foo; 1 + return_from(foo 2) + 3; },
) {
	eval $decl.$_;
	is $@, "";
}

foreach(
	q{ block; },
	q{ block(foo; },
	q{ block(foo); },
	q{ block((foo {})); },
	q{ block(foo {}, 1); },
	q{ block foo my $y = 1; },
	q{ block(foo {}) my $y = 1; },
	q{ no warnings "syntax"; block foo; return_from foo, 1; },
) {
	eval $decl.$_;
	like $@, qr/\Asyntax error/;
}

foreach(
	q{ block foo; 1 + return_from foo 2; },
	q{ block foo; 1 + (return_from foo 2); },
	q{ block foo; 1 + (return_from foo 2) + 3; },
) {
	eval $decl.$_;
	if("$]" >= 5.013008) {
		is $@, "";
	} else {
		like $@, qr/\Asyntax error/;
	}
}

1;
