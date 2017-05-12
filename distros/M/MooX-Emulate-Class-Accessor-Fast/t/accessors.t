#!/usr/bin/env perl
use strictures 1;

use Test::More;

{
  package Vanilla;
  use Moo;
  with 'MooX::Emulate::Class::Accessor::Fast';

  __PACKAGE__->mk_accessors('foo_rw');
  __PACKAGE__->mk_ro_accessors('foo_ro');
  __PACKAGE__->mk_wo_accessors('foo_wo');
}

{
  package FollowBestPractice;
  use Moo;
  with 'MooX::Emulate::Class::Accessor::Fast';

  __PACKAGE__->follow_best_practice();

  __PACKAGE__->mk_accessors('foo_rw');
  __PACKAGE__->mk_ro_accessors('foo_ro');
  __PACKAGE__->mk_wo_accessors('foo_wo');
}

{
  package CustomReader;
  use Moo;
  with 'MooX::Emulate::Class::Accessor::Fast';

  sub accessor_name_for {
    return 'get_' . $_[1];
  }

  __PACKAGE__->mk_accessors('foo_rw');
  __PACKAGE__->mk_ro_accessors('foo_ro');
  __PACKAGE__->mk_wo_accessors('foo_wo');
}

{
  package CustomWriter;
  use Moo;
  with 'MooX::Emulate::Class::Accessor::Fast';

  sub mutator_name_for {
    return 'set_' . $_[1];
  }

  __PACKAGE__->mk_accessors('foo_rw');
  __PACKAGE__->mk_ro_accessors('foo_ro');
  __PACKAGE__->mk_wo_accessors('foo_wo');
}

my @all_methods = (
  map { $_, "get_$_", "set_$_" }
  qw( foo_rw foo_ro foo_wo )
);

my @tests = (
  [ Vanilla => qw( foo_rw foo_ro foo_wo ) ],
  [ FollowBestPractice => qw( get_foo_rw set_foo_rw get_foo_ro set_foo_wo ) ],
  [ CustomReader => qw( get_foo_rw foo_rw get_foo_ro foo_wo ) ],
  [ CustomWriter => qw( foo_ro foo_rw set_foo_rw set_foo_wo ) ],
);

foreach my $test (@tests) {
  my ($class, @methods) = @$test;
  my $obj = $class->new();

  my $methods_lookup = { map{$_=>1} @methods };

  my @not_methods = (
    grep { !$methods_lookup->{$_} }
    @all_methods
  );

  ok( $obj->can($_), "$class can $_" ) for @methods;
  ok( (!$obj->can($_)), "$class cannot $_" ) for @not_methods;
}

done_testing;
