use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

{
    package MyRole;
    use Moose::Role;
    requires 'foo';
}

eval q{

    package MyClass;
    use Moose;
    use MooseX::Types -declare => ['Foo'];
    use MooseX::Types::Moose 'Int';
    with 'MyRole';

    subtype Foo, as Int;

    sub foo {}
};

ok !$@, 'type export not picked up as a method on role application';

done_testing();
