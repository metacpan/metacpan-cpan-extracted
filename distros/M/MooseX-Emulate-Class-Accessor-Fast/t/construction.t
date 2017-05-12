#!perl
use strict;
use Test::More tests => 9;

#1
require_ok("MooseX::Emulate::Class::Accessor::Fast");

{
  package MyClass;
  use Moose;
  with 'MooseX::Emulate::Class::Accessor::Fast';
}

{
  package MyClass::MooseChild;
  use Moose;
  extends 'MyClass';
}

{
  package MyClass::ImmutableMooseChild;
  use Moose;
  extends 'MyClass';
  __PACKAGE__->meta->make_immutable(allow_mutable_ancestors => 1);
}

{
  package MyClass::TraditionalChild;
  use base qw(MyClass);
}

{
  package MyImmutableClass;
  use Moose;
  with 'MooseX::Emulate::Class::Accessor::Fast';
  __PACKAGE__->meta->make_immutable;
}

{
  package MyImmutableClass::MooseChild;
  use Moose;
  extends 'MyImmutableClass';
}

{
  package MyImmutableClass::ImmutableMooseChild;
  use Moose;
  extends 'MyImmutableClass';
  __PACKAGE__->meta->make_immutable;
}

{
  package MyImmutableClass::TraditionalChild;
  use base qw(MyImmutableClass);
}

# 2-9
foreach my $class (qw/
                      MyClass 
                      MyImmutableClass 
                      MyClass::MooseChild 
                      MyClass::ImmutableMooseChild  
                      MyClass::TraditionalChild 
                      MyImmutableClass::MooseChild 
                      MyImmutableClass::ImmutableMooseChild 
                      MyImmutableClass::TraditionalChild
                                                           /) {
    my $instance = $class->new(foo => 'bar');
    is($instance->{foo}, 'bar', $class . " has CAF construction behavior");
}

