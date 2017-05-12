{

  package MyObject;
  use Moo;
  use MooX::Types::MooseLike::Base qw<ArrayRef Int>;
  has attribute_with_a_default => (
    is      => 'ro',
    isa     => ArrayRef [Int],
    default => sub { [ 52, 27, 108 ] },
    );
}
use Test::More;
use Test::Fatal;

is_deeply(
  MyObject->new->attribute_with_a_default,
  [ 52, 27, 108 ],
  'Parameterized type with a default'
  );

done_testing;
