package Paws::SQS::Implementation::CreateQueue;
  use Moose;
  with 'Paws::API::Server::Call';

  sub evaluate_access { 1; }

  has injectable => (is => 'ro', default => 'queue.localhost');

  sub process {
    my $self = shift;

    my $name = $self->params->QueueName;

    die "Text of an unstructured exception" if ($name eq '+UnstructuredException');
    Moose->throw_error('Text of a structured exception') if ($name eq '+StructuredException');

    Paws::API::Server::Exception->throw(message => "My QueueName has invalid chars", code => 'InvalidName') if ($name !~ m/^[A-Za-z0-9_-]{1,80}$/);

    my $host = $self->injectable;

    Paws->load_class($self->returns_a);
    return $self->returns_a->new(
      QueueUrl => "http://$host/queues/$name",
    );
  }


  __PACKAGE__->meta->make_immutable;
1;
