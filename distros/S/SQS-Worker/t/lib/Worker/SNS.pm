package Worker::SNS {
  use Moose;
  with 'SQS::Worker', 'SQS::Worker::SNS';

  use Test::More;

  sub process_message {
    my ($self, $m) = @_;

    isa_ok($m, 'SNS::Notification');
  }

}
1;
