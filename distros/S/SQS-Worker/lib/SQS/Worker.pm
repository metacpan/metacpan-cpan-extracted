package SQS::Worker;
use Paws;
use Moose::Role;
use Data::Dumper;
use SQS::Consumers::Default;
use SQS::Consumers::DeleteAlways;
use SQS::Consumers::DeleteAndFork;

our $VERSION = '0.06';

requires 'process_message';

has queue_url => (is => 'ro', isa => 'Str', required => 1);
has region => (is => 'ro', isa => 'Str', required => 1);

has sqs => (is => 'ro', isa => 'Paws::SQS', lazy => 1, default => sub {
    my $self = shift;
    Paws->service('SQS', region => $self->region);
});

has log => (is => 'ro', required => 1);

has on_failure => (is => 'ro', isa => 'CodeRef', default => sub {
    return sub {
        my ($self, $message) = @_;
        $self->log->error("Error processing message " . $message->ReceiptHandle);
        $self->log->debug("Message Dump " . Dumper($message));
    }
});

has processor => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    return SQS::Consumers::Default->new;
});

sub fetch_message {
    my $self = shift;
    $self->processor->fetch_message($self);
}

sub run {
    my $self = shift;
    while (1) {
        $self->fetch_message;
    }
}

sub delete_message {
    my ($self, $message) = @_;
    $self->sqs->DeleteMessage(
        QueueUrl      => $self->queue_url,
        ReceiptHandle => $message->ReceiptHandle,
    );
}

sub receive_message {
    my $self = shift;
    my $message_pack = $self->sqs->ReceiveMessage(
        WaitTimeSeconds => 20,
        QueueUrl => $self->queue_url,
        MaxNumberOfMessages => 1
    );
    return $message_pack;
}

1;

=head1 NAME

SQS::Worker - A light framework for processing messages from SQS queues

=head1 DESCRIPTION

SQS::Worker is a light framework that allows you to just code asyncronous tasks
that consume messages from an SQS Queue. The framework takes care of launching the 
necessary processes (workers), and executes your code on incoming messages, so you
can focus on writing the important part (behavior)

Also, since you're surely going to be deserializing the messages that come from the
queue, SQS::Worker provides you with ways to easily consume JSON messages, for example.

It comes in the form of a Moose role that is to be composed into the end user code 
that wants to receive and process messages from an SQS queue. 

The worker runs uninterrumped, fetching messages from it's configured queue, 
one at a time and then executing the process_message of the worker class.

The worker consumer can compose further funcionality by consuming more roles 
from the SQS::Worker namespace.

=head1 USAGE

Simple usage

	package YourWorker;

	use Moose;
	with 'SQS::Worker';

	sub process_message {
		my ($self,$message) = @_;

    # $message is a Paws::SQS::Message
		# do something with the message 
	}

Composing automatic json decoding to perl data structure

	package YourWorker;
  use Moose;
	with 'SQS::Worker', 'SQS::Worker::DecodeJson';

	sub process_message {
		my ($self, $data) = @_;
		
		# Do something with the data, already parsed into a structure
		my $name = $data->{name};

    # You get a logger attached to the worker so you can log stuff
    $c->log->info("I processed a message for $name");
	}

=head1 Bundled roles

L<SQS::Worker::DecodeJson> decodes the message body in json format and passes 

L<SQS::Worker::DecodeStorable> decodes the message body in Perl storable format

L<SQS::Worker::Multiplex> dispatches to different methods via a dispatch table

L<SQS::Worker::SNS> decodes a message sent from SNS and inflates it to a C<SNS::Notfication>

=head1 Creating your own processing module

Create a Moose role that wraps functionality around the method C<process_message>

  package PrefixTheMessage;
    use Moose::Role;

    around process_message => sub {
      my ($orig, $self, $message) = @_;
      return 'prefixed ' . $message->Body;
    };

  1;

And then use it inside your consumers

  package YourWorker;
  
	use Moose;
	with 'SQS::Worker', 'PrefixTheMessage';
  
	sub process_message {
		my ($self, $message) = @_;
    # surprise! $message is prefixed!
  }
  
  1;

=head1 Composing roles

The worker roles can be composed (if it makes sense), so your worker could implement

  with 'SQS::Worker', 'SQS::Worker::DecodeJson', 'SQS::Worker::Multiplex';

to decode a message in json format that will then dispatch the json to the multiplex worker

=head1 Error handling

Any exception thrown from process_message will be treated as a failed message. Different
message processors treat failed messages in different ways:

=head1 Message processors

L<SQS::Consumers::Default> Messages processed before deleting them from the queue. If a message fails, 
it will be treated by SQS as an unprocessed message, and will reappear in the queue to be processed
again by SQS (or delivered to a dead letter queue after N redeliveries if your SQS queue is configured 
appropiately

L<SQS::Consumers::DeleteAlways> Message deleted, then processed. If a message fails it will
not be reprocessed ever

=head1 Running the worker

Running the worker can be done via the C<spawn_worker> command that comes bundled with the 
distribution

  spawn_worker --worker YourWorker --queue_url sqs_endpoint_url --region aws_sqs_region --log_conf log4perl_config_file_path

You can also control if the message should be deleted upon reception (before the message is actually processed) with

 spawn_worker --worker YourClass --queue_url sqs_endpoint_url --region aws_sqs_region --log_conf log4perl_config_file_path --consumer DeleteAlways

or you can create an instance of your object and invoke run:

  my $worker_instance = YourWorker->new(
    queue_url => $args->queue_url,
    region    => $args->region,
    log => Log::Log4perl->get_logger('async'),
    processor => $args->_consumer,
  );
  $worker_instance->run

=head1 Credentials

SQS::Worker uses the same credential system as L<Paws> to authenticate to SQS: so, in a nutshell, it
will work if you:

=over

=item *

have the credentials in the home of the user launching the script, in the ~/.aws/credentials file.

=item *

assign an IAM role to the EC2 instance that is running the code (if deploying the code inside an EC2 instance)

=item *

set environment variables: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY

=back

=head1 SEE ALSO
 
L<Paws>
 
=head1 COPYRIGHT and LICENSE
 
Copyright (c) 2016 by CAPSiDE
 
This code is distributed under the Apache 2 License. The full text of the license can be found in the LICENSE file included with this module.
 
=head1 AUTHORS

Jose Luis Martinez, Albert Hilazo, Pau Cervera and Loic Prieto

=cut
