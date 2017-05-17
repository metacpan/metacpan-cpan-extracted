package TestMessage {
  use Moose;

  has Body => (is => 'ro');
  has ReceiptHandle => (is => 'ro');
}
1;