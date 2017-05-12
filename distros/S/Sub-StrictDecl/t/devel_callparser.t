use warnings;
use strict;

BEGIN {
	eval { require Devel::CallParser };
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all => "Devel::CallParser unavailable");
	}
}

use Test::More tests => 4;

use Devel::CallParser ();

my $r;

$r = eval(q{
	use Sub::StrictDecl;
	if(0) { foo0(); }
	1;
});
is $r, undef;
like $@, qr/\AUndeclared subroutine &main::foo0/;

$r = eval(q{
	use Sub::StrictDecl;
	sub foo1;
	if(0) { foo1(); }
	1;
});
is $r, 1;
is $@, "";

1;
