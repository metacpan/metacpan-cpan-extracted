package SQS::Consumers::Default;
use Moose;
use namespace::autoclean;

sub fetch_message {
    my $self = shift;
    my $worker = shift;

    $worker->log->debug('Receiving Messages');
    my $message_pack = $worker->receive_message();

    $worker->log->debug(sprintf "Got %d messages", scalar(@{ $message_pack->Messages }));

    foreach my $message (@{$message_pack->Messages}) {
        $worker->log->info("Processing message " . $message->ReceiptHandle);
        eval {
            $worker->process_message($message);
        };

        if ($@) {
            $worker->log->error("Exception caught: " . $@);
            $worker->on_failure->($worker, $message);
        } else {
            # If all went well we have to delete the message from the queue
            $worker->delete_message($message);
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;
