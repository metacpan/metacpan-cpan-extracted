package SQS::Worker::SNS;
  use Moose::Role;
  use SNS::Notification;
  use JSON::MaybeXS;

  around process_message => sub {
    my ($orig, $self, $message) = @_;

    my $body;
    eval {
      $body = decode_json($message->Body)
    };
    if ($@) {
      $self->log->error("Worker::SNS Error decoding JSON body in message " . $message->ReceiptHandle . ": " . $@ . " for content " . $message->Body);
      die $@;
    } else {
      die "SNS body should parse to a hashref" if (ref($body) ne 'HASH');
      my $sns = eval { SNS::Notification->new($body) };
      if ($@){
        die "SNS Worker couldn't convert the message to a SNS::Notification: $@";
      } else {
        return $self->$orig($sns);
      }
    }
  };

1;
