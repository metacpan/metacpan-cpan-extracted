use strict;
use warnings;
use Smart::Args;
use Test::More;
use t::Util;

{
    package MyClass;
    sub new { bless {} }
}

sub foo{
    args my $x => "ArrayRef[Int]";
    return $x;
}

sub bar{
    args my $x => "MyClass";
    return $x;
}

lives_and{
    is_deeply foo(x => [10]), [10];
};

lives_and{
    isa_ok bar(x => MyClass->new()), 'MyClass';
};

throws_ok{
    foo(x => { foo => 42 });
} qr/Validation failed/;

throws_ok{
    foo(x => [3.14]);
} qr/Validation failed/;

throws_ok{
    foo(x => bless {}, 'Foo');
} qr/Validation failed/;

done_testing;
