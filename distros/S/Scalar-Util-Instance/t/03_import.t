#!perl -w
use strict;
use Test::More tests => 9;
use Test::Exception;

use Scalar::Util::Instance
    { for => 'Foo', as => 'is_a_Foo' },
    { for => 'Bar', as => 'A::is_a_Bar' },
;

BEGIN{
    package Foo;
    sub new{ bless {}, shift }

    package Bar;
    our @ISA = qw(Foo);

    package Baz;
    sub new{ bless {}, shift }
}

ok is_a_Foo(Foo->new);
ok is_a_Foo(Bar->new);
ok!is_a_Foo(Baz->new);

ok!A::is_a_Bar(Foo->new);
ok A::is_a_Bar(Bar->new);
ok!A::is_a_Bar(Baz->new);

lives_ok{
    Scalar::Util::Instance->import();
};

throws_ok{
    Scalar::Util::Instance->import({for => 'Foo'});
} qr/You must define a predicate name/;

throws_ok{
    Scalar::Util::Instance->import({as => 'is_a_Foo'});
} qr/You must define a class name/;
