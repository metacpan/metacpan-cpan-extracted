use strict;
use warnings;
use Test::More;

package MyApp {
	use MooX::Pression;
	role Foo {
		requires bar (Str $x, Num $y);
		requires baz;
	}
}

ok !eval q{
	package Local::Class1;
	use Moo;
	with 'MyApp::Foo';
	1;
};

ok !eval q{
	package Local::Class2;
	use Moo;
	with 'MyApp::Foo';
	sub baz { 42 }
	1;
};

ok eval q{
	package Local::Class3;
	use Moo;
	with 'MyApp::Foo';
	sub bar { 24 }
	sub baz { 42 }
	1;
};

done_testing;

