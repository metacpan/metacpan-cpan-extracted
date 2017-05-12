use warnings;
use strict;

use Test::More tests => 46;

use Scope::Escape::Sugar qw(with_escape_function with_escape_continuation);

my(@events, @value);

@events = ();
@value = sub {
	push @events, [ "aa0" ];
	with_escape_function $cont;
	push @events, [ "aa1", ref($cont) ];
	$cont->("aa2a", "aa2b");
	push @events, [ "aa3" ];
	("aa4a", "aa4b");
}->();
push @events, [ "bb0", [@value] ];
is_deeply \@events, [
	[ "aa0" ],
	[ "aa1", "CODE" ],
	[ "bb0", [ "aa2a", "aa2b" ] ],
];

@events = ();
@value = sub {
	push @events, [ "aa0" ];
	with_escape_function $cont {
		push @events, [ "aa1", ref($cont) ];
		$cont->("aa2a", "aa2b");
		push @events, [ "aa3" ];
		("aa4a", "aa4b");
	}
}->();
push @events, [ "bb0", [@value] ];
is_deeply \@events, [
	[ "aa0" ],
	[ "aa1", "CODE" ],
	[ "bb0", [ "aa2a", "aa2b" ] ],
];

@events = ();
@value = sub {
	push @events, [ "aa0" ];
	@value = with_escape_function($cont {
		push @events, [ "aa1", ref($cont) ];
		$cont->("aa2a", "aa2b");
		push @events, [ "aa3" ];
		("aa4a", "aa4b");
	});
	push @events, [ "aa5", [@value] ];
	("aa6a", "aa6b");
}->();
push @events, [ "bb0", [@value] ];
is_deeply \@events, [
	[ "aa0" ],
	[ "aa1", "CODE" ],
	[ "aa5", [ "aa2a", "aa2b" ] ],
	[ "bb0", [ "aa6a", "aa6b" ] ],
];

@events = ();
@value = sub {
	push @events, [ "aa0" ];
	with_escape_continuation $cont;
	push @events, [ "aa1", !!$cont->isa("Scope::Escape::Continuation") ];
	$cont->("aa2a", "aa2b");
	push @events, [ "aa3" ];
	("aa4a", "aa4b");
}->();
push @events, [ "bb0", [@value] ];
is_deeply \@events, [
	[ "aa0" ],
	[ "aa1", !!1 ],
	[ "bb0", [ "aa2a", "aa2b" ] ],
];

@events = ();
@value = sub {
	push @events, [ "aa0" ];
	with_escape_continuation $cont {
		push @events, [ "aa1",
				!!$cont->isa("Scope::Escape::Continuation") ];
		$cont->("aa2a", "aa2b");
		push @events, [ "aa3" ];
		("aa4a", "aa4b");
	}
}->();
push @events, [ "bb0", [@value] ];
is_deeply \@events, [
	[ "aa0" ],
	[ "aa1", !!1 ],
	[ "bb0", [ "aa2a", "aa2b" ] ],
];

@events = ();
@value = sub {
	push @events, [ "aa0" ];
	@value = with_escape_continuation($cont {
		push @events, [ "aa1",
				!!$cont->isa("Scope::Escape::Continuation") ];
		$cont->("aa2a", "aa2b");
		push @events, [ "aa3" ];
		("aa4a", "aa4b");
	});
	push @events, [ "aa5", [@value] ];
	("aa6a", "aa6b");
}->();
push @events, [ "bb0", [@value] ];
is_deeply \@events, [
	[ "aa0" ],
	[ "aa1", !!1 ],
	[ "aa5", [ "aa2a", "aa2b" ] ],
	[ "bb0", [ "aa6a", "aa6b" ] ],
];

my $decl = "use Scope::Escape::Sugar qw(with_escape_function);\n";

foreach(
	q{ with_escape_function$e; },
	q{ with_escape_function $e; },
	q{ with_escape_function$ e; },
	q{ with_escape_function$e ; },
	q{ { with_escape_function$e; } },
	q{ { with_escape_function$e } },
	q{ {with_escape_function$e} },
	q{with_escape_function$e},
	q{ with_escape_function$ab; },
	q{ with_escape_function$a_; },
	q{ with_escape_function$aB; },
	q{ with_escape_function$a0; },
	q{ with_escape_function$Ab; },
	q{ with_escape_function$_b; },
	q{ with_escape_function$_; },
	q{ with_escape_function$e{} },
	q{ with_escape_function $e{} },
	q{ with_escape_function$ e{} },
	q{ with_escape_function$e {} },
	q{ with_escape_function$e{ } },
	q{ with_escape_function($e{}) },
	q{ with_escape_function ($e{}) },
	q{ with_escape_function( $e{}); },
	q{ with_escape_function($ e{}); },
	q{ with_escape_function($e {}); },
	q{ with_escape_function($e{ }); },
	q{ with_escape_function($e{} ); },
	q{ with_escape_function($e{}) ; },
	q{ with_escape_function $e; my $y = 1; },
	q{ with_escape_function $e {} my $y = 1; },
	q{ with_escape_function($e {}); my $y = 1; },
) {
	eval $decl.$_;
	is $@, "";
}

foreach(
	q{ with_escape_function; },
	q{ with_escape_function$0b; },
	q{ with_escape_function$0; },
	q{ with_escape_function($e; },
	q{ with_escape_function($e); },
	q{ with_escape_function(($e {})); },
	q{ with_escape_function($e {}, 1); },
	q{ with_escape_function $e my $y = 1; },
	q{ with_escape_function($e {}) my $y = 1; },
) {
	eval $decl.$_;
	like $@, qr/\Asyntax error/;
}

1;
