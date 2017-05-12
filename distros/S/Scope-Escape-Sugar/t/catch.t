use warnings;
use strict;

use Test::More tests => 56;

use Scope::Escape::Sugar qw(catch throw);

my(@events, @value);

sub bb() {
	push @events, [ "bb0" ];
	push @events, [ "bb1a", throw("wibble", "bb2b", "bb2c"), "bb1d" ];
	push @events, [ "bb2" ];
	("bb3a", "bb3b");
}

@events = ();
@value = sub {
	push @events, [ "aa0" ];
	catch "wibble";
	push @events, [ "aa1" ];
	push @events, [ "aa2a", bb(), "aa2b" ];
	push @events, [ "aa3" ];
	("aa4a", "aa4b");
}->();
push @events, [ "cc0", [@value] ];
is_deeply \@events, [
	[ "aa0" ],
	[ "aa1" ],
	[ "bb0" ],
	[ "cc0", [ "bb2b", "bb2c" ] ],
];

@events = ();
@value = sub {
	push @events, [ "aa0" ];
	catch "wibble" {
		push @events, [ "aa1" ];
		push @events, [ "aa2a", bb(), "aa2b" ];
		push @events, [ "aa3" ];
		("aa4a", "aa4b");
	}
}->();
push @events, [ "cc0", [@value] ];
is_deeply \@events, [
	[ "aa0" ],
	[ "aa1" ],
	[ "bb0" ],
	[ "cc0", [ "bb2b", "bb2c" ] ],
];

@events = ();
@value = sub {
	push @events, [ "aa0" ];
	@value = catch("wibble" {
		push @events, [ "aa1" ];
		push @events, [ "aa2a", bb(), "aa2b" ];
		push @events, [ "aa3" ];
		("aa4a", "aa4b");
	});
	push @events, [ "aa5", [@value] ];
	("aa6a", "aa6b");
}->();
push @events, [ "cc0", [@value] ];
is_deeply \@events, [
	[ "aa0" ],
	[ "aa1" ],
	[ "bb0" ],
	[ "aa5", [ "bb2b", "bb2c" ] ],
	[ "cc0", [ "aa6a", "aa6b" ] ],
];

is catch("a" {
	100 + catch("a" {
		throw("a", 10);
		20;
	});
}), 110;

is catch("a" {
	100 + catch("b" {
		throw("a", 10);
		20;
	});
}), 10;

is catch("a" {
	1000 + catch("a" {
		100 + catch("a" {
			throw("a", 10);
			20;
		});
	});
}), 1110;

is catch("a" {
	1000 + catch("a" {
		100 + catch("b" {
			throw("a", 10);
			20;
		});
	});
}), 1010;

is catch("a" {
	1000 + catch("b" {
		100 + catch("a" {
			throw("a", 10);
			20;
		});
	});
}), 1110;

is catch("b" {
	1000 + catch("a" {
		100 + catch("a" {
			throw("a", 10);
			20;
		});
	});
}), 1110;

is catch("a" {
	1000 + catch("b" {
		100 + catch("b" {
			throw("a", 10);
			20;
		});
	});
}), 10;

is eval { catch("a" { throw("a", 30); 40; }) }, 30;
is $@, "";

is eval { catch("b" { throw("a", 30); 40; }) }, undef;
like $@, qr/\Ano catcher named "a" is visible/;

is eval { catch("b" { throw(undef, 30); 40; }) }, undef;
like $@, qr/\Athrow tag is not a string/;

my $ta = "oo";
is catch("f$ta" { throw("foo", 30); 40; }), 30;
is catch("foo" { throw("f$ta", 30); 40; }), 30;
is catch("foo" { throw("f".$ta, 30); 40; }), 30;

my $th = \&throw;
is catch("foo" { $th->("foo", 30); 40; }), 30;
is eval { catch("foo" { $th->(); 40; }) }, undef; isnt $@, "";

my $decl = "use Scope::Escape::Sugar qw(catch throw);\n";

foreach(
	q{ catch"foo"; },
	q{ catch"foo" ; },
	q{ catch "foo"; },
	q{ { catch"foo"; } },
	q{ { catch"foo" } },
	q{ {catch"foo"} },
	q{catch"foo"},
	q{ catch"foo\"bar" },
	q{ catch"foo'bar" },
	q{ catch 'foo'; },
	q{ catch 'foo"bar'; },
	q{ my $bar = 1; catch"foo$bar" },
	q{ catch"foo"{} },
	q{ catch "foo"{} },
	q{ catch"foo" {} },
	q{ catch"foo"{ } },
	q{ catch("foo"{}); },
	q{ catch ("foo"{}); },
	q{ catch( "foo"{}); },
	q{ catch("foo" {}); },
	q{ catch("foo"{ }); },
	q{ catch("foo"{} ); },
	q{ catch("foo"{}) ; },
	q{ catch "foo"; my $y = 1; },
	q{ catch "foo" {} my $y = 1; },
	q{ catch("foo" {}); my $y = 1; },
) {
	eval $decl.$_;
	is $@, "";
}

foreach(
	q{ catch; },
	q{ catch$foo; },
	q{ catch("foo"; },
	q{ catch("foo"); },
	q{ catch(("foo" {})); },
	q{ catch("foo" {}, 1); },
	q{ catch "foo" my $y = 1; },
	q{ catch("foo" {}) my $y = 1; },
) {
	eval $decl.$_;
	like $@, qr/\Asyntax error/;
}

1;
