package SQS::Worker::Client {
  use Moose;
  use Paws;
  use JSON::MaybeXS;
  use MIME::Base64;
  use Storable qw/nfreeze/;

  has queue_url => (is => 'ro', isa => 'Str', required => 1);
  has region    => (is => 'ro', isa => 'Str', required => 1);

  has serializer  => (is => 'ro', isa => 'Str', default => 'json');
  has _serializer => (is => 'ro', isa => 'HashRef[CodeRef]', default => sub {
    return {
      json     => sub { return encode_json \@_; },
      storable => sub { return encode_base64( nfreeze \@_ ); }
    }
  });

  has sqs => (is => 'ro', isa => 'Paws::SQS', lazy => 1, default => sub {
    my $self = shift;
    Paws->service('SQS', region => $self->region);
  });

  sub serialize_params {
    my ($self, @params) = @_;

    $self->_serializer->{$self->serializer}(@params);
  }

  sub call {
    my ($self, @params) = @_;

    my $serialized = $self->serialize_params(@params);

    my $message_pack = $self->sqs->SendMessage(
      MessageBody => $serialized,
      QueueUrl => $self->queue_url
    );
  }
}
1;