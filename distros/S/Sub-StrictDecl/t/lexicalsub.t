use warnings;
use strict;

BEGIN {
	eval { require Lexical::Sub };
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all => "Lexical::Sub unavailable");
	}
}

use Test::More tests => 2;

my $r;

$r = eval(q{
	use Sub::StrictDecl;
	use Lexical::Sub foo => sub { };
	if(0) { print \&foo; }
	1;
});
is $r, 1;
is $@, "";

1;
