package TestKeyValueCodingInheritance;

use strict;
use warnings;

use base qw(
    Test::Class
);

use Test::More;


sub test_inheritance : Tests {
    my ( $self ) = @_;

    my $child  = _InheritanceTestThing->new();
    my $parent = _ParentTestThing->new();
    my $grandParent = _GrandParentTestThing->new();

    foreach my $object ( $child, $parent, $grandParent ) {
        $object->setValueForKey( "This is Boo", "boo" );
        $object->setValueForKey( "This is Goo", "goo" );
        $object->setValueForKey( "This is Foo", "foo" );
    }

    ok( $grandParent->valueForKey("boo") eq "This is Boo", "grandparent vfk boo" );
    ok( $grandParent->{__boo} eq "This is Boo", "grandparent fishing boo" );
    ok( $grandParent->valueForKey("goo") eq "This is Goo", "grandparent vfk goo" );
    ok( $grandParent->{__goo} eq "This is Goo", "grandparent fishing goo" );
    ok( $grandParent->valueForKey("foo") eq "This is Foo", "grandparent vfk foo" );
    ok( $grandParent->{__foo} eq "This is Foo", "grandparent fishing foo" );

    ok( $parent->valueForKey("boo") eq "This is Boo", "parent vfk boo" );
    ok( $parent->{boo_} eq "This is Boo", "parent fishing boo" );
    ok( $parent->valueForKey("goo") eq "This is Goo", "parent vfk goo" );
    ok( $parent->{goo_} eq "This is Goo", "parent fishing goo" );
    ok( $parent->valueForKey("foo") eq "This is Foo", "parent vfk foo" );
    ok( $parent->{__foo} eq "This is Foo", "parent fishing foo" );

    ok( $child->valueForKey("boo") eq "This is Boo", "child vfk boo" );
    ok( $child->{b_oo} eq "This is Boo", "child fishing boo" );
    ok( $child->valueForKey("goo") eq "This is Goo", "child vfk goo" );
    ok( $child->{goo_} eq "This is Goo", "child fishing goo" );
    ok( $child->valueForKey("foo") eq "This is Foo", "child vfk foo" );
    ok( $child->{__foo} eq "This is Foo", "child fishing foo" );
}


package _GrandParentTestThing;

use Object::KeyValueCoding;

sub new { bless {}, $_[0] }

sub boo    { return $_[0]->{__boo}  }
sub setBoo { $_[0]->{__boo} = $_[1] }

sub goo     { return $_[0]->{__goo}  }
sub set_goo { $_[0]->{__goo} = $_[1] }

sub _foo    { return $_[0]->{__foo}  }
sub _setFoo { $_[0]->{__foo} = $_[1] }



package _ParentTestThing;

use base qw( _GrandParentTestThing );

sub boo     { return $_[0]->{boo_}  }
sub setBoo  { $_[0]->{boo_} = $_[1] }

sub goo     { return $_[0]->{goo_}  }
sub set_goo { $_[0]->{goo_} = $_[1] }


package _InheritanceTestThing;

use base qw( _ParentTestThing );

sub boo     { return $_[0]->{b_oo}  }
sub setBoo  { $_[0]->{b_oo} = $_[1] }


1;