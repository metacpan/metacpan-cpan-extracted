package Spread::Queue::Sender;

=head1 NAME

Spread::Queue::Sender - submit messages to Spread::Queue message queues

=head1 SYNOPSIS

  use Spread::Queue::Sender;

  my $sender = new Spread::Queue::Sender(QUEUE => "myqueue");

  $sender->submit({ name => "value" });
  my $response = $sender->receive;

or

  my $response = $sender->rpc({ name => "value" });

=head1 DESCRIPTION

A Spread::Queue::Sender can submit messages for queued delivery to
the first available Spread::Queue::Worker.  The sqm queue manager
must be running to receive and route messages.

Spread::Queue messages are Perl hashes, serialized by Data::Serializer,
by default using Data::Denter.

Spread::Queue does not enforce structure on message contents.

=head1 METHODS

=cut

require 5.005_03;
use strict;
use vars qw($VERSION);
$VERSION = '0.4';

use Spread::Session;
use Data::Serializer;
use Carp;
use Log::Channel;
use Digest::MD5;
use Time::HiRes;

my $DEFAULT_TIMEOUT = 5;

BEGIN {
    my $sqslog = new Log::Channel;
    sub sqslog { $sqslog->(@_) }
}

=item B<new>

  my $serlzr = new Data::Serialization(serializer => "YAML");
  my $sender = new Spread::Queue::Sender(QUEUE => "myqueue",
					 SERIALIZER => $serlzr);

Establish Spread session for transmitting messages to a queue of workers.
The SERIALIZER parameter is optional, by default using Data::Denter.

=cut

my $SingleSession;

sub new {
    my $proto = shift;
    my $class = ref ($proto) || $proto;

    my %config = @_;
    my $self  = \%config;
    bless ($self, $class);

    # configuration options: override default timeout

    $self->{QUEUE} = $ENV{SPREAD_QUEUE} unless $self->{QUEUE};
    croak "Queue name is required" unless $self->{QUEUE};

    $self->{MQNAME} = "MQ_$self->{QUEUE}";

    if ($SingleSession) {
	$self->{SESSION} = $SingleSession;
    } else {
	$self->{SESSION} = new Spread::Session (
						MESSAGE_CALLBACK => \&_message_callback,
						TIMEOUT_CALLBACK => \&_timeout_callback,
					       );
	$SingleSession = $self->{SESSION};
    }

    if (! $self->{SERIALIZER}) {
	$self->{SERIALIZER} = new Data::Serializer(serializer => "Data::Denter");
    }
    my $serlzr = $self->{SERIALIZER}->serializer;

    sqslog "Message queue submitter initialized on $self->{QUEUE}, using $serlzr\n";

    return $self;
}

=item B<submit>

  $sender->submit($data);

$data should be a hashref, which will be serialized and published as
a Spread message.

=cut

my $Outbound;

sub submit {
    my ($self, $payload) = @_;

    my $content = $self->{SERIALIZER}->serialize($payload);
#    my $digest = Digest::MD5::md5($content);
    $self->{SESSION}->publish($self->{MQNAME},
			      $content);
    $Outbound = Time::HiRes::gettimeofday;
}

=item B<receive>

  my $response = $sender->receive($timeout);

Wait for an incoming message on the sender's private Spread address.  This
is just a pass-through to Spread::Session::receive.

=cut

sub receive {
    my $self = shift;
				# a 0-sec timeout is not the same as undef
    my $timeout = defined $_[0] ? shift : $DEFAULT_TIMEOUT;

    my $msg = $self->{SESSION}->receive($timeout, $self);

    if ($msg->{type} eq "ack") {
	# this is an acknowledgement for an earlier outbound msg
	my $elapsed = Time::HiRes::gettimeofday - $Outbound;
	sqslog "Elapsed seconds: $elapsed\n";
	return $self->receive($timeout);
    } else {
	return $msg->{body};
    }
}

=item B<rpc>

  my $response = $sender->rpc($data [, $timeout]);

RPC-style invocation of a remote operation.  Waits $timeout seconds
for a response (returns undef if no response arrives).

=cut

sub rpc {
    my ($self, $payload, $timeout) = @_;

    $self->submit($payload);
    return $self->receive($timeout);
}


sub _message_callback {
    my ($msg, $self) = @_;

    return $self->{SERIALIZER}->deserialize($msg->{BODY});
}

sub _timeout_callback {
    my ($self) = @_;

    return;
}

=item B<admin>

  $sender->status;

Transmit an administrative status request to the queue manager.

=cut

sub status {
    my ($self, $content) = @_;

    $self->{SESSION}->publish($self->{MQNAME},
			      "^^status");
    $Outbound = Time::HiRes::gettimeofday;
}


1;
