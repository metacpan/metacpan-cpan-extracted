#!/usr/bin/perl

use v5.14;
use warnings;
use utf8;

use Test2::V0;

package TestObject {
   use Sentinel;

   sub new { return bless { foo => undef }, $_[0] }

   sub get_foo { return $_[0]->{foo} }
   sub set_foo { $_[0]->{foo} = $_[1] }

   # These names are non-ASCII
   sub get_ĝi { goto &get_foo }
   sub set_ĝi { goto &set_foo }

   package TestObject;
   sub foo :lvalue
   {
      my $self = shift;
      sentinel obj => $self, 
               get => \&get_foo,
               set => \&set_foo;
   }

   sub foo_utf8 :lvalue
   {
      my $self = shift;
      sentinel obj => $self,
               get => "get_ĝi",
               set => "set_ĝi";
   }

   sub foo_named :lvalue
   {
      my $self = shift;
      sentinel obj => $self,
               get => "get_foo",
               set => "set_foo";
   }
}

my $obj = TestObject->new;

is( $obj->get_foo, undef, '$obj->get_foo undef before set' );
is( $obj->foo,     undef, '$obj->foo undef before set' );

$obj->set_foo( "Hello" );

is( $obj->get_foo, "Hello", '$obj->get_foo after set via ->set' );
is( $obj->foo,     "Hello", '$obj->foo after set via ->set' );

$obj->foo = "Goodbye";

is( $obj->get_foo, "Goodbye", '$obj->get_foo after set via lvalue' );
is( $obj->foo,     "Goodbye", '$obj->foo after set via lvalue' );

$obj->foo .= " world!";

is( $obj->get_foo, "Goodbye world!", '$obj->foo allows mutator operators' );

is( $obj->foo_named, "Goodbye world!", '$obj->foo_named performs method name lookup' );

$obj->foo_named = "Another message";

is( $obj->get_foo, "Another message", '$obj->get_foo after set via lvalue named' );

is( $obj->foo_utf8, "Another message", '$obj->foo_utf8 performs method name lookup' );

$obj->foo_utf8 = "Yet another message";

is( $obj->get_foo, "Yet another message", '$obj->get_foo after set via lvalue utf8' );

done_testing;
