use strict;
use warnings;
use Test::More 0.88;

{
    package MyTypes;
    use MooseX::Types::Structured qw(Dict Tuple Optional);
    use MooseX::Types::Moose qw(Object Any);
    use MooseX::Types -declare => [qw(
        Signature
        MyDict
        MyTuple
    )];

    subtype Signature, as Tuple[Tuple[Object], Dict[optional => Optional[Any], required => Any]];

    subtype MyDict, as Dict[optional => Optional[Any], required => Any];

    subtype MyTuple, as Tuple[Object, Any, Optional[Any]];
}

BEGIN {
    MyTypes->import(':all');
}

ok(!Signature->check([ [bless {}, 'Foo'], {} ]));

ok(!MyDict->check({ }));
ok(!MyDict->check({ optional => 42 }));
ok(!MyDict->check({ optional => 42, unknown => 23 }));
ok(!MyDict->check({ required => 42, unknown => 23 }));

ok(MyDict->check({ optional => 42, required => 23 }));
ok(MyDict->check({ required => 23 }));

ok(!MyTuple->check([]));
ok(!MyTuple->check([bless({}, 'Foo')]));
ok(!MyTuple->check([bless({}, 'Foo'), 'bar', 'baz', 'moo']));

ok(MyTuple->check([bless({}, 'Foo'), 'bar']));
ok(MyTuple->check([bless({}, 'Foo'), 'bar', 'baz']));

done_testing;
