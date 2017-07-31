package FakeSQS;
  use Moose;
  use Paws;
  use Paws::SQS::Message;
  use Paws::Exception;
  use UUID qw/uuid/;

  has url => (
    is => 'ro',
    isa => 'Str',
    default => 'http://sqs.fake.amazonaws.com/123456789012/'
  );

  has queues => (
    is => 'ro',
    #isa => 'HashRef[ArrayRef[Paws::SQS::Message]',
    isa => 'HashRef',
    default => sub { {} },
  );

  sub add_message_to_queue {
    my ($self, $qname, $m) = @_;
    push @{ $self->queues->{ $qname } }, $m;
  }

  sub get_messages_from_qname {
    my ($self, $qname, $number) = @_;

    my @result;
    
    my $num = 0;
    while ($num < $number) {
      push @result, shift @{ $self->queues->{ $qname } };
      $num++;
    }

    return \@result;
  }

  sub CreateQueue {
    my ($self, $params) = @_;

    my $qname = $params->QueueName;
    if (defined $self->queues->{ $qname }) {
      Paws::Exception->throw(message => "Queue already exists", code => 'AlreadyExists');
    }

    # initialize the queue
    $self->queues->{ $qname } = [];

    return {
      QueueUrl => $self->url . $qname,
    }
  }

  sub DeleteQueue {
    my ($self, $params) = @_;
    my $qname = $self->get_qname_from_queue_url($params->QueueUrl);

    delete $self->queues->{ $qname };
  }

  sub SendMessage {
    my ($self, $params) = @_;

    my $qname = $self->get_qname_from_queue_url($params->QueueUrl);
    my $m = Paws::SQS::Message->new(
      Body => $params->MessageBody,
      MessageId => uuid,
    );

    $self->add_message_to_queue($qname, $m);

    return {
      MessageId => $m->MessageId,
    }
  }

  sub ReceiveMessage {
    my ($self, $params) = @_;

    my $qname = $self->get_qname_from_queue_url($params->QueueUrl);

    my $messages = $self->get_messages_from_qname($qname, 1);

    return {
      Messages => $messages
    }
  }

  sub get_qname_from_queue_url {
    my ($self, $q_url) = @_;
    my $base_url = $self->url;
    my ($q_name) = ($q_url =~ m/^$base_url(.*)$/);
    Paws::Exception->throw(message => 'Invalid Queue', code => 'InvalidQueue') if (not defined $q_name);
    Paws::Exception->throw(
      message => "Queue doesn't exist",
      code => 'NotFound'
    ) if (not exists $self->queues->{ $q_name });
    return $q_name;
  }

  __PACKAGE__->meta->make_immutable;
1;
