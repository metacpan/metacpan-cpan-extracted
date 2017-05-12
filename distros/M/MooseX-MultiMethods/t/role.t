use strict;
use warnings;
use Test::More tests => 3;

{
    package MyRole;
    use Moose::Role;
    use MooseX::MultiMethods;

    multi method foo (Int $x) { 'Int' }
    multi method foo (Str $x) { 'Str' }
}
{
    package MyClass;
    use Moose;
    with 'MyRole';
}

use Test::Exception;

my $obj = MyClass->new;
is $obj->foo(1),       'Int';
is $obj->foo('Hello'), 'Str';
throws_ok {
    is $obj->foo([]),      'Array';
} qr/no variant of method 'foo' found for/;

1;
