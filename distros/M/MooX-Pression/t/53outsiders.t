use strict;
use warnings;
use Test::More;

my $counter = 0;

package MyApp {
	use MooX::Pression;
	
	class Quux;
	
	method foo (Int $x) { 1000 + $x }
	
	multi method bar (ArrayRef $x) { 'ARRAY' }
	multi method bar (HashRef $y)  { 'HASH' }
	
	before bar { ++$counter }
	
	constant baz = 999;
	
	package MyApp::Other;
	method xyzzy { 666 }
}

is(MyApp->foo(-1), 999);
is(MyApp->foo(1000), 2000);

is(MyApp->bar([]), 'ARRAY');
is(MyApp->bar({}), 'HASH');
is($counter, 2);

is(MyApp->baz, 999);

is(MyApp::Other->xyzzy, 666);

done_testing;
