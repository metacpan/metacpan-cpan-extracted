#!/usr/bin/env perl
use strictures 2;
use Test2::V0;

require MooX::Emulate::Class::Accessor::Fast;

{
  package MyClass;
  use Moo;
  with 'MooX::Emulate::Class::Accessor::Fast';
}

{
  package MyClass::MooChild;
  use Moo;
  extends 'MyClass';
}

{
  package MyClass::ImmutableMooChild;
  use Moo;
  extends 'MyClass';
  __PACKAGE__->meta->make_immutable(allow_mutable_ancestors => 1);
}

{
  package MyClass::TraditionalChild;
  use base qw(MyClass);
}

{
  package MyImmutableClass;
  use Moo;
  with 'MooX::Emulate::Class::Accessor::Fast';
  __PACKAGE__->meta->make_immutable;
}

{
  package MyImmutableClass::MooChild;
  use Moo;
  extends 'MyImmutableClass';
}

{
  package MyImmutableClass::ImmutableMooChild;
  use Moo;
  extends 'MyImmutableClass';
  __PACKAGE__->meta->make_immutable;
}

{
  package MyImmutableClass::TraditionalChild;
  use base qw(MyImmutableClass);
}

foreach my $class (qw/
                      MyClass 
                      MyImmutableClass 
                      MyClass::MooChild 
                      MyClass::ImmutableMooChild  
                      MyClass::TraditionalChild 
                      MyImmutableClass::MooChild 
                      MyImmutableClass::ImmutableMooChild 
                      MyImmutableClass::TraditionalChild
                                                           /) {
    my $instance = $class->new(foo => 'bar');
    is($instance->{foo}, 'bar', $class . " has CAF construction behavior");
}

done_testing;
