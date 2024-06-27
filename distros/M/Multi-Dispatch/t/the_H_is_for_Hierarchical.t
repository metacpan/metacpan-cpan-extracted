use 5.022;
use warnings;
use strict;

use Test::More;
plan tests => 9;

use Multi::Dispatch;

package BaseClass {
    multimethod foo ($x :where({$x > 0})) {
        return 'BaseClass::foo';
    }

    multimethod bar ($x :where({$x > 0})) {
        return 'BaseClass::bar';
    }

    multimethod baz ($x :where({$x > 0})) {
        return 'BaseClass::baz';
    }
}

package DerivedClass {
    use parent -norequire, 'BaseClass';

    multimethod foo ($x) {
        return 'DerivedClass::foo';
    }

    multimethod bar ($x :where({$x > 0})) {
        return 'DerivedClass::bar';
    }

    multimethod baz :before ($x :where({$x > 0})) {
        return 'DerivedClass::baz';
    }
}

package RederivedClass {
    use parent -norequire, 'DerivedClass';

    multimethod foo ($x) {
        return 'RederivedClass::foo';
    }

    multimethod bar ($x :where({$x > 0})) {
        return 'RederivedClass::bar';
    }

    multimethod baz ($x :where({$x > 0})) {
        return 'RederivedClass::baz';
    }
}


my $obj = bless {}, 'RederivedClass';

is $obj->foo(42), 'BaseClass::foo'      => 'RederivedClass: most constrained';
is $obj->bar(42), 'RederivedClass::bar' => 'RederivedClass: most derived';
is $obj->baz(42), 'DerivedClass::baz'   => 'RederivedClass: most begun';


$obj = bless {}, 'DerivedClass';

is $obj->foo(42), 'BaseClass::foo'    => 'DerivedClass: most constrained';
is $obj->bar(42), 'DerivedClass::bar' => 'DerivedClass: most derived';
is $obj->baz(42), 'DerivedClass::baz' => 'DerivedClass: most begun';


$obj = bless {}, 'BaseClass';

is $obj->foo(42), 'BaseClass::foo' => 'BaseClass: most constrained';
is $obj->bar(42), 'BaseClass::bar' => 'BaseClass: most derived';
is $obj->baz(42), 'BaseClass::baz' => 'BaseClass: most begun';

done_testing();








