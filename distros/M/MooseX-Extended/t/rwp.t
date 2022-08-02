#!/usr/bin/env perl

use lib 't/lib';
use MooseX::Extended::Tests;

package My::Object {
    use MooseX::Extended;

    param some_param => ( is => 'rwp' );
    field some_field => ( is => 'rwp' );
}

my $thing = My::Object->new( some_param => 42 );
is $thing->some_param, 42, 'Our param should be set correctly';
ok !defined $thing->some_field, '... and our field should start out unset';
throws_ok { $thing->some_param(4) }
'Moose::Exception::CannotAssignValueToReadOnlyAccessor', 'Trying to assign to a read-only rwp accessor shoold fail';

ok $thing->_set_some_param('red'),  'rwp creates a "private" writer for a param';
ok $thing->_set_some_field('blue'), 'rw creates a "private" writer for a field';

is $thing->some_param, 'red',  'The param writer set the correct value';
is $thing->some_field, 'blue', 'The field writer set the correct value';

done_testing;
