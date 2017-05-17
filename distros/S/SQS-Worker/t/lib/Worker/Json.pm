package Worker::Json {
  use Moose;
  with 'SQS::Worker', 'SQS::Worker::DecodeJson';

  use Test::More;

  sub process_message {
    my ($self, $p1, $p2, $p3, $p4) = @_;

    cmp_ok($p1, '==', 1);
    cmp_ok($p2, 'eq', 'param2');
    is_deeply($p3, [1,2,3]);
    is_deeply($p4, { a => 'hash'});
  }

}
1;