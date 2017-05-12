{

  package MyObject;
  use Moo;
  use MooX::Types::MooseLike::Base qw<HashRef>;

  has required_parameterized_hashref => (
    is       => "ro",
    isa      => HashRef [HashRef],
    required => 1,
    );
}
use Test::More;
use Test::Fatal;
ok(MyObject->new(required_parameterized_hashref => { a => {} }),
  'Required parameterized type');
like(
  exception { MyObject->new },
  qr/Missing required arguments/,
  'A required parameterized type must exist'
  );

done_testing;
