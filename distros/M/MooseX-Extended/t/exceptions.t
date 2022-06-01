#!/usr/bin/env perl

use lib 'lib';
use Test::Most;
use MooseX::Extended::Core qw(param field);
use MooseX::Extended::Role ();
use Capture::Tiny 'capture_stderr';

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

throws_ok { field( $meta, 'created', init_arg => 'created' ) }
'Moose::Exception::InvalidAttributeDefinition',
  'We should get a proper exception if we pass an init_arg to field';

explain 'capture_stderr will hide the carp(), but the exception is thrown before it can return STDERR';
throws_ok {
    capture_stderr { MooseX::Extended->import( not => 'allowed' ) }
}
'Moose::Exception::InvalidImportList',
  'Passing an invalid import list to MooseX::Extended should throw an exception';

throws_ok {
    capture_stderr { MooseX::Extended::Role->import( not => 'allowed' ) }
}
'Moose::Exception::InvalidImportList',
  'Passing an invalid import list to MooseX::Extended::Role should throw an exception';

done_testing;
