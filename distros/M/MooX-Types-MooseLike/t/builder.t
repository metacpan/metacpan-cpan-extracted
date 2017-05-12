{

  package MyObject;
  use Moo;
  use MooX::Types::MooseLike::Base qw<ArrayRef CodeRef>;
  has attribute_with_a_builder => (
    is      => 'ro',
    isa     => ArrayRef [CodeRef],
    builder => '_build_attribute_properties',
    );

  sub _build_attribute_properties {
    [ sub { 'pie' } ];
  }
}

use Test::More;
my $object = MyObject->new;
is($object->attribute_with_a_builder->[0]->(),
  'pie', 'Parameterized type with a builder');

done_testing;
