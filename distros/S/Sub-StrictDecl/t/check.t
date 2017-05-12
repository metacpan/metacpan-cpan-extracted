use warnings;
use strict;

use Test::More tests => 58;

BEGIN { $^H |= 0x20000; }

my $r;

$r = eval(q{
	use Sub::StrictDecl;
	# sub call
	if(0) { foo0(); }
	1;
});
is $r, undef;
like $@, qr/\AUndeclared subroutine &main::foo0/;

$r = eval(q{
	use Sub::StrictDecl;
	# sub call
	sub foo1;
	if(0) { foo1(); }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use Sub::StrictDecl;
	# sub call
	sub foo2 ();
	if(0) { foo2(); }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use Sub::StrictDecl;
	# sub call
	sub foo3 {}
	if(0) { foo3(); }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use Sub::StrictDecl;
	# sub call
	BEGIN { *foo4 = sub { }; }
	if(0) { foo4(); }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use Sub::StrictDecl;
	# sub call
	*foo5 = sub { };
	if(0) { foo5(); }
	1;
});
is $r, undef;
like $@, qr/\AUndeclared subroutine &main::foo5/;

$r = eval(q{
	use Sub::StrictDecl;
	# sub ref
	if(0) { print \&bar0; }
	1;
});
is $r, undef;
like $@, qr/\AUndeclared subroutine &main::bar0/;

$r = eval(q{
	use Sub::StrictDecl;
	# sub ref
	sub bar1;
	if(0) { print \&bar1; }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use Sub::StrictDecl;
	# sub ref
	sub bar2 ();
	if(0) { print \&bar2; }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use Sub::StrictDecl;
	# sub ref
	sub bar3 {}
	if(0) { print \&bar3; }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use Sub::StrictDecl;
	# sub ref
	BEGIN { *bar4 = sub { }; }
	if(0) { print \&bar4; }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use Sub::StrictDecl;
	# sub ref
	*bar5 = sub { };
	if(0) { print \&bar5; }
	1;
});
is $r, undef;
like $@, qr/\AUndeclared subroutine &main::bar5/;

$r = eval(q{
	use Sub::StrictDecl;
	# sub call
	if(0) { Baz::baz0(); }
	1;
});
is $r, undef;
like $@, qr/\AUndeclared subroutine &Baz::baz0/;

$r = eval(q{
	use Sub::StrictDecl;
	# sub call
	sub Baz::baz1;
	if(0) { Baz::baz1(); }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use Sub::StrictDecl;
	no warnings qw(reserved void);
	# bare string
	if(0) { quux0a; }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use Sub::StrictDecl;
	# sub call
	sub quux0b;
	if(0) { quux0b; }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use Sub::StrictDecl;
	# sub call
	sub quux1b;
	if(0) { quux1b 1; }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use Sub::StrictDecl;
	# indirect method call
	if(0) { my $x; quux2a $x; }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use Sub::StrictDecl;
	# sub call
	sub quux2b;
	if(0) { my $x; quux2b $x; }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use Sub::StrictDecl;
	no warnings "reserved";
	# bare string (and direct method call)
	if(0) { quux3a->x; }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use Sub::StrictDecl;
	# sub call (and direct method call)
	sub quux3b;
	if(0) { quux3b->x; }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use Sub::StrictDecl;
	# bare string (and direct method call)
	sub quux4a::x {}
	if(0) { quux4a->x; }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use Sub::StrictDecl;
	# sub call (and direct method call)
	sub quux4b::x {}
	sub quux4b;
	if(0) { quux4b->x; }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use Sub::StrictDecl;
	# indirect method call
	if(0) { quux5a Quux5a; }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use Sub::StrictDecl;
	# sub call
	sub quux5b;
	if(0) { quux5b Quux5b; }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use Sub::StrictDecl;
	# indirect method call
	sub Quux6a::quux6a {}
	if(0) { quux6a Quux6a; }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use Sub::StrictDecl;
	# indirect method call
	sub Quux6b::quux6b {}
	sub quux6b;
	if(0) { quux6b Quux6b; }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use Sub::StrictDecl;
	# bare string
	if(0) { my @x = (quux7a=>1); }
	1;
});
is $r, 1;
is $@, "";

$r = eval(q{
	use Sub::StrictDecl;
	# bare string
	sub quux7b;
	if(0) { my @x = (quux7b=>1); }
	1;
});
is $r, 1;
is $@, "";

1;
