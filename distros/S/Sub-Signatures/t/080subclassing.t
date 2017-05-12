#!/usr/bin/perl
# '$Id: 70subclassing.t,v 1.1 2004/12/05 21:19:33 ovid Exp $';
use warnings;
use strict;
use Test::More 'no_plan';

#use Test::More tests => 16;
use Test::Exception;

my $CLASS;

BEGIN {

    #    $ENV{DEBUG} = 1;
    chdir 't' if -d 't';
    unshift @INC => '../lib', 'test_lib/';
    $CLASS = 'ClassB';
    use_ok $CLASS or die;
}

can_ok $CLASS, 'foo';
is $CLASS->foo( [ 6, 6, 6 ] ), "arrayref with 3 elements",
  '... and it should behave as expected';

is_deeply $CLASS->foo( { that => 2 } ), { this => 1, that => 2 },
  '... and we can even specify different types.';

ok $CLASS->match( 'this', qr/hi/ ),
  '... and we can overload the methods as much as we like';

ok !$CLASS->match( 'this', qr/ih/ ),
  '... and we can overload the methods as much as we like';

ok $CLASS->match( [qw/this hi hit thistle/], qr/hi/ ),
  '... but overloading on type is still handled internally';

my $object = $CLASS->new;
isa_ok( $object, $CLASS );
ok $object->match( 'this', qr/hi/ ),
  '... and we can overload the methods as much as we like';

ok !$object->match( 'this', qr/ih/ ),
  '... and we can overload the methods as much as we like';

ok $object->match( [qw/this hi hit thistle/], qr/hi/ ),
  '... but overloading on type is still handled internally';

is $object->match(3), 3, 'Overloading methods on number of args should work';

can_ok $CLASS, 'bar';
is $CLASS->bar('foo'), 'foo', 'We should be able to call the normal method';

is_deeply $CLASS->bar( 1, 2, 3 ), [ 'fallback', 'ClassB', 1, 2, 3 ],
  '... and have fallbacks work for methods, too';
