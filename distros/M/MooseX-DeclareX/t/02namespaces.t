use MooseX::DeclareX keywords => [qw(class role exception)], plugins => [qw(build)];
use Test::More tests => 3;

class Foo {
	class ::Bar {
		::is(__PACKAGE__, 'Foo::Bar');
	}
}

class Foo {
	class ::Bar {
		role ::Baz {
			exception ::Quux {
				::is(__PACKAGE__, 'Foo::Bar::Baz::Quux');
				build monkey { 1 }
			}
		}
	}
}

can_ok('Foo::Bar::Baz::Quux', 'monkey');
