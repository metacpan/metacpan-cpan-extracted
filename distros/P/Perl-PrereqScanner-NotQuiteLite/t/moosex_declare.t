use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::More;
use t::Util;

test('Foo in t/lib/Foo.pm', <<'END', {'MooseX::Declare' => 0});
use MooseX::Declare;

class Foo {
    has 'affe' => (
        is  => 'ro',
        isa => 'Str',
    );

    method foo ($x) { $x }

    method inner { 23 }

    method bar ($moo) { "outer(${moo})-" . inner() }

    class ::Bar is mutable {
        method bar { blessed($_[0]) ? 0 : 1 }
    }

    class ::Baz {
        method baz {}
    }
}
END

test('Role in t/lib/Foo.pm', <<'END', {'MooseX::Declare' => 0});
use MooseX::Declare;

role Role {
    requires 'required_thing';
    method role_method {}
}
END

test('Moo::Kooh in t/lib/Foo.pm', <<'END', {'MooseX::Declare' => 0, Foo => 0, Role => 0});
use MooseX::Declare;

class Moo::Kooh {
    extends 'Foo';

    around foo ($x) { $x + 1 }

    augment bar ($moo) { "inner(${moo})" }

    method kooh {}
    method required_thing {}

    with 'Role';
}
END

test('Corge in t/lib/Foo.pm', <<'END', {'MooseX::Declare' => 0, 'Foo::Baz' => 0, Role => 0});
use MooseX::Declare;

class Corge extends Foo::Baz with Role {
    method corge {}
    method required_thing {}
}
END

test('Quux in t/lib/Foo.pm', <<'END', {'MooseX::Declare' => 0, 'Corge' => 0});
use MooseX::Declare;

class Quux extends Corge {
    has 'x' => (
        is  => 'ro',
        isa => 'Int',
    );

    method quux {}
}
END

test('SecondRole in t/lib/Foo.pm', <<'END', {'MooseX::Declare' => 0});
use MooseX::Declare;

role SecondRole {}
END

test('SecondRole in t/lib/Foo.pm', <<'END', {'MooseX::Declare' => 0, 'Role' => 0, 'SecondRole' => 0});
use MooseX::Declare;

class MultiRole with Role with SecondRole {
    method required_thing {}
}
END

test('SecondRole in t/lib/Foo.pm', <<'END', {'MooseX::Declare' => 0, 'Role' => 0, 'SecondRole' => 0});
use MooseX::Declare;

class MultiRole2 with (Role, SecondRole) {
    method required_thing {}
}
END

test('manual namespace', <<'END', {'MooseX::Declare' => 0, 'Foo::Bar::Baz' => 0, 'Foo::Bar::Fnording' => 0});
use MooseX::Declare;

namespace Foo::Bar;

sub base { __PACKAGE__ }

class ::Baz {
    sub TestPackage::baz { __PACKAGE__ }
}

role ::Fnording {
    sub TestPackage::fnord { __PACKAGE__ }
}

class ::Qux extends ::Baz with ::Fnording {
    sub TestPackage::qux { __PACKAGE__ }
}
END

test('manual namespace', <<'END', {'MooseX::Declare' => 0, 'Foo::Z' => 0, 'Foo::A' => 0, 'Foo::B' => 0, 'Foo::C' => 0});
use MooseX::Declare;

namespace Foo;

role ::Z {
    method foo (Int $x) { $x }
}

role ::C {
    with '::Z';
    around foo (Int $x) { $self->$orig(int($x / 3)) }
}

role ::B {
    with '::C';
    around foo (Int $x) { $self->$orig($x + 2) }
}

role ::A {
    with '::B';
    around foo (Int $x) { $self->$orig($x * 2) }
}

class TEST {
    with '::A';
    around foo (Int $x) { $self->$orig($x + 2) }
}

class AnotherTest {
    with '::Z';
    around foo (Int $x) { $self->$orig($x * 2) }
}
END

done_testing;
