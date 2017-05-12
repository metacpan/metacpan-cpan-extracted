use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

{
    package MyClass;
    use Moose;
    use Test::Requires 'MooseX::Method::Signatures';
    use MooseX::AlwaysCoerce;
    use Moose::Util::TypeConstraints;

    BEGIN {
        subtype 'MyType', as 'Int';
        coerce 'MyType', from 'Str', via { length $_ };

        subtype 'Uncoerced', as 'Int';
    }

    method foo (MyType :$foo, Uncoerced :$bar) {
        return "$foo $bar";
    }
}

use Test::Fatal;

ok( (my $instance = MyClass->new), 'instance' );

TODO: {
    local $TODO = 'need rafl to help with implementation';

    is( exception {
        is $instance->foo(foo => "text", bar => 42), '4 42';
    }, undef, 'method called with coerced and uncoerced parameters' )
        or todo_skip 'is() test never ran', 1;
}

done_testing;
