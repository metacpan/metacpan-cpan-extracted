package Worker::Json2 {
  use Moose;
  with 'SQS::Worker', 'SQS::Worker::DecodeJson';

  use Test::More;

  sub process_message {
    my ($self, $p1, $p2) = @_;

    ok(!defined $p2);
    is_deeply($p1, { a => 'hash' });
  }

}
1;
