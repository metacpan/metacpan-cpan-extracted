package Paws::Net::ImplementationCaller::EC2 {
  use Moose;
  extends 'Paws::Net::ImplementationCaller::PASLoader';

  has '+api' => (default => sub { 'EC2' });

  sub get_user {
    return undef;
  }
}
1;
