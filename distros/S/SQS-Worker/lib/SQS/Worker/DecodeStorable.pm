package SQS::Worker::DecodeStorable {
  use Moose::Role;
  use MIME::Base64;
  use Storable qw/thaw/;


  around process_message => sub {
    my ($orig, $self, $message) = @_;

    my $body;
    eval {
      $body = thaw( decode_base64($message->Body) );
    };
    if ($@) {
      $self->log->error("Error retrieving store file in message " . $message->ReceiptHandle . ": " . $@ . " for content " . $message->Body);
      die $@;
    } else {
      return $self->$orig(@$body);
    }
  };

}
1;