package Paws::SQS::Implementation::DeleteQueue;
  use Moose;
  with 'Paws::API::Server::Call';

  sub evaluate_access { 1; }

  sub process {
    my $self = shift;

    return 1;
  }

1;
