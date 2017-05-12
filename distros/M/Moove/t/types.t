#!perl

use Test::Most;

plan tests => 2;

use Moove -autoclass;

func foobar (Foo::Bar $foobar) {
    1;
}

lives_ok {
    foobar(bless([], 'Foo::Bar'));
};

throws_ok {
    foobar(bless([], 'Bar::Foo'));

} qr{Reference .*? \Qdid not pass type constraint "FooBar" (not isa Foo::Bar)\E};

done_testing;
