package Paws::Net::ImplementationCaller::SQS {
  use Moose;
  extends 'Paws::Net::ImplementationCaller::PASLoader';

  has '+api' => (default => sub { 'SQS' });

  sub get_user {
    return undef;
  }
}
1;
