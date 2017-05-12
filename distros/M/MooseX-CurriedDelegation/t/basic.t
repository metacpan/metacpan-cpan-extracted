use strict;
use warnings;

use Test::More;
use Test::Moose 'has_attribute_ok';
use Test::Moose::More;

{
    package TestClass::Delagatee;
    use Moose;

    sub curried { shift; return @_ }
    sub to_self { ref $_[1]        }
}
{
    package TestClass;

    use Moose;
    use MooseX::CurriedDelegation;

    has one => (is => 'ro', isa => 'Str', default => 'default');

    has foo => (

        is      => 'rw',
        isa     => 'TestClass::Delagatee',
        default => sub { TestClass::Delagatee->new() },

        handles => {

            foo_del_one => { curried => [ sub { shift->one }, qw{ more curry args } ] },
            foo_del_two => { to_self => [ curry_to_self ] },
        },
    );

}

our $tc = 'TestClass';

with_immutable {

    meta_ok $tc;

    has_attribute_ok $tc, 'foo', 'one';
    has_method_ok $tc, 'foo', 'foo_del_one';

    my $test = $tc->new(one => 'not_default');

    is_deeply(
        [ $test->foo_del_one                ],
        [ qw{ not_default more curry args } ],
        'simple method currying works as expected',
    );

    is $test->foo_del_two, 'TestClass', 'curry_to_self works as expected';

} 'TestClass';

done_testing;
