#!/usr/bin/env perl

use lib 'lib';
use Test::Most;
use MooseX::Extended::Core qw(param field);

package Mock::Meta {
    use MooseX::Extended;
    sub name {'My::Class'}
}

my $meta = Mock::Meta->new;
throws_ok { param( $meta, 'foo', isa => 'Str', writer => 'foo_Array(x1233)' ) }
'Moose::Exception::InvalidAttributeDefinition',
  'We should get a proper exception if our attributes have invalid property names';

throws_ok { param( $meta, '42foo', isa => 'Str', writer => 'set_foo' ) }
'Moose::Exception::InvalidAttributeDefinition',
  'We should get a proper exception if our attributes have attribute names';

done_testing;
