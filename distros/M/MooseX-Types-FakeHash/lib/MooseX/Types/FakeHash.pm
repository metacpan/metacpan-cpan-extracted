use strict;
use warnings;

package MooseX::Types::FakeHash;
BEGIN {
  $MooseX::Types::FakeHash::AUTHORITY = 'cpan:KENTNL';
}
{
  $MooseX::Types::FakeHash::VERSION = '0.1.2';
}

# ABSTRACT: Types for emulating Hash-like behaviours with ArrayRefs.

use MooseX::Types;
use Moose::Util::TypeConstraints ();
use Moose::Meta::TypeConstraint::Parameterizable;
use Moose::Meta::TypeConstraint::Parameterized;


## no critic ( RequireArgUnpacking Capitalization )
sub _constraint_KeyWith {
  return unless ref($_) eq 'ARRAY';    # its an array
  return unless @{$_} == 2;            # and it has exactly 2 keys.
  return 1;
}

sub _constraint_FakeHash {
  return unless ref($_) eq 'ARRAY';    # its an array
  return if scalar @{$_} & 1;          # and it has a multiple of 2 keys ( bitwise checks for even, 0 == true )
  return 1;
}

sub _constraint_OrderedFakeHash {
  return unless ref($_) eq 'ARRAY';    # its an array
  return 1;
}

sub _optimised_constraint_KeyWith  { return ref( $_[0] ) eq 'ARRAY' && scalar @{ $_[0] } == 2 }
sub _optimised_constraint_FakeHash { return ref( $_[0] ) eq 'ARRAY' && !( scalar @{ $_[0] } & 1 ) }
sub _optimised_constraint_OrderedFakeHash { return ref( $_[0] ) eq 'ARRAY' }

my $STR_check = Moose::Util::TypeConstraints::find_type_constraint('Str')->_compiled_type_constraint;

sub _constraint_generator_KeyWith {
  my $type_parameter = shift;
  my $check          = $type_parameter->_compiled_type_constraint;
  return sub {
    $STR_check->( $_->[0] ) || return;
    $check->( $_->[1] )     || return;
    1;
  };
}

sub _constraint_generator_FakeHash {
  my $type_parameter = shift;
  my $check          = $type_parameter->_compiled_type_constraint;
  return sub {
    my @items = @{$_};
    my $i     = 0;
    while ( $i <= $#items ) {
      $STR_check->( $items[$i] )   || return;
      $check->( $items[ $i + 1 ] ) || return;
    }
    continue {
      $i += 2;
    }

    1;
  };
}

sub _constraint_generator_OrderedFakeHash {
  my $type_parameter = shift;
  my $subtype        = Moose::Meta::TypeConstraint::Parameterized->new(
    name           => 'OrderedFakeHash::KeyWith[' . $type_parameter->name . ']',
    parent         => _type_KeyWith(),
    type_parameter => $type_parameter,
  );
  return sub {
    for my $pair ( @{$_} ) {
      $subtype->assert_valid($pair) || return;
    }
    1;
  };
}

my $type_cache = {};

sub _mk_type {
  my (%args) = @_;
  my $name = $args{name};
  return $type_cache->{$name} if exists $type_cache->{$name};

  my $type = $type_cache->{$name} = Moose::Meta::TypeConstraint::Parameterizable->new(
    package_defined_in   => __PACKAGE__,
    parent               => Moose::Util::TypeConstraints::find_type_constraint('Ref'),
    constraint           => __PACKAGE__->can( '_constraint_' . $name ),
    optimised_constraint => __PACKAGE__->can( '_optimised_constraint_' . $name ),
    constraint_generator => __PACKAGE__->can( '_constraint_generator_' . $name ),
    %args,
  );
  Moose::Util::TypeConstraints::register_type_constraint($type);
  Moose::Util::TypeConstraints::add_parameterizable_type($type);
  return $type;
}

sub _type_KeyWith         { return _mk_type( name => 'KeyWith', ) }
sub _type_FakeHash        { return _mk_type( name => 'FakeHash', ) }
sub _type_OrderedFakeHash { return _mk_type( name => 'OrderedFakeHash' ) }

sub _setup {
  _type_KeyWith;
  _type_FakeHash;
  _type_OrderedFakeHash;
  return 1;
}




_setup();

sub type_storage {
  return { map { ($_) x 2 } qw( KeyWith FakeHash OrderedFakeHash ) };
}

no Moose::Util::TypeConstraints;

1;

__END__

=pod

=head1 NAME

MooseX::Types::FakeHash - Types for emulating Hash-like behaviours with ArrayRefs.

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

=head2 Standard Non-MooseX-Types style invocation

  package #
    Foo;

  use Moose;
  use MooseX::Types::FakeHash;

  has foo => (
    isa => 'KeyWith[ ArrayRef ]'
    is  => 'rw',
    required => 1,
  );

  has bar => (
    isa      => 'ArrayRef[ KeyWith[ Str ] ]',
    is       => 'rw',
    required => 1,
  );

  ....


  Foo->new(
    foo => [ Hello => [] ]
    bar => [
       [ "Content-Type" => "text/plain" ],
       [ "X-Zombies"    => "0"          ],
    ],
  );

=head2 MooseX-Types style invocation

  package #
    Foo;

  use Moose;
  use MooseX::Types::FakeHash qw( :all );
  use MooseX::Types::Moose    qw( :all );

  has foo => (
    isa => KeyWith[ ArrayRef ]
    is  => 'rw',
    required => 1,
  );

  has bar => (
    isa      => ArrayRef[ KeyWith[ Str ] ],
    is       => 'rw',
    required => 1,
  );

  ....


  Foo->new(
    foo => [ Hello => [] ]
    bar => [
       [ "Content-Type" => "text/plain" ],
       [ "X-Zombies"    => "0"          ],
    ],
  );

=head1 TYPES

=head2 KeyWith

=head2 KeyWith[ X ]

A parameterizable type intended to simulate a singular key/value pair stored in an array.

The keys is required to be of type C<Str>, while the value is the parameterized type.

  has bar ( isa => KeyWith[ Foo ] , ... );

  ...

  ->new(
    bar => [ "Key" => $fooitem ] # [ Str, Foo ]
  );

=head2 FakeHash

=head2 FakeHash[ X ]

A parameterizable type intended to simulate the values of a HashRef, but stored in an ArrayRef instead
as an even number of key/values.

The keys are required to be of type C<Str>, while the value is the parameterized type.

  has bar ( isa => FakeHash[ Foo ] , ... );

  ...

  ->new(
    bar => [
      "Key"           => $fooitem,
      "AnotherKey"    => $baritem,
      "YetAnotherKey" => $quuxitem,
    ] # [ Str, Foo, Str, Foo, Str, Foo ]
  );

=head2 OrderedFakeHash

=head2 OrderedFakeHash[ X ]

A parameterizable type intended to simulate the values of a HashRef, but stored in an ArrayRef instead
as an array of L</KeyWith> items. This is much like a L</FakeHash>, but slightly different, in that the paring of the Key/Value is stricter,
and numerical-offset based lookup is simpler.

  [
     [ "Key" => $value ],
     [ "Key" => $value ],
  ]

In essence, OrderedFakeHash[ x ] is ShortHand for ArrayRef[ KeyWith[ x ] ].

This makes it harder to convert to a native Perl 5 Hash, but somewhat easier to iterate pairwise.

  my $data = $object->orderedfakehashthing();
  for my $pair ( @($data) ){
    my ( $key, $value ) = @{ $pair };
    ....
  }

The keys are required to be of type C<Str>, while the value is the parameterized type.

  has bar ( isa => OrderedFakeHash[ Foo ] , ... );

  ...

  ->new(
    bar => [
      [ "Key"           => $fooitem  ],
      [ "AnotherKey"    => $baritem  ],
      [ "YetAnotherKey" => $quuxitem ],
    ] # [ [ Str, Foo ],[ Str, Foo ],[ Str, Foo ] ]
  );

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
