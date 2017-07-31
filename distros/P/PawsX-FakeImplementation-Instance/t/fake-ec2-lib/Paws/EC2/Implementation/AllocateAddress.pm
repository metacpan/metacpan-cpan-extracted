package Paws::EC2::Implementation::AllocateAddress;
  use Moose;
  with 'Paws::API::Server::Call';

  sub evaluate_access { 1; }

  sub process {
    my $self = shift;
    return 1;
  }

1; 
