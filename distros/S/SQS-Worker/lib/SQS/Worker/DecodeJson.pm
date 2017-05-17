package SQS::Worker::DecodeJson;
  use Moose::Role;
  use JSON::MaybeXS;


  around process_message => sub {
    my ($orig, $self, $message) = @_;

    my $body;
    eval {
      $body = decode_json($message->Body)
    };
    if ($@) {
      $self->log->error("Error decoding JSON body in message " . $message->ReceiptHandle . ": " . $@ . " for content " . $message->Body);
      die $@;
    } else {
      if (ref($body) eq 'ARRAY'){
        return $self->$orig(@$body);
      } else {
        return $self->$orig($body);
      }
    }
  };

1;
