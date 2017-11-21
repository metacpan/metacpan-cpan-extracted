package Net::NATS::Streaming::Client;
use strict;
use warnings;
use Scalar::Util 'blessed';
use UUID;
use Net::NATS::Streaming::PB;
use base 'Net::NATS::Client';
use Class::XSAccessor {
    accessors => [
        'clusterID',
        'clientID',
        'connect_request',
        'connect_response',
        'cluster_discover_subject',
        'heartbeats_seen',
        'heartbeat_subscription'
    ],
};

our $VERSION = '0.03';
our $CLUSTER_ID = 'test-cluster';
our $CLUSTER_DISCOVER_SUBJECT = '_STAN.discover';
our $ACK_WAIT = 30;
our $MAX_INFLIGHT = 1024;
our $CONNECT_TIMEOUT = 2;
our $MAX_PUB_ACKS_INFLIGHT = 16384;
our $WAIT_FOR_OP_TIMEOUT = 120;
our $PUB_NOACK = 0;

sub uuidgen
{
    UUID::generate(my $uuid);
    UUID::unparse($uuid, my $string);
    return $string;
}

sub connect
{
    my $self = shift;
    return unless $self->SUPER::connect(@_);
    return $self->connect_stream;
}

sub connect_stream
{
    my $self = shift;
    $self->heartbeats_seen(0);
    my $connect_request = Net::NATS::Streaming::PB::ConnectRequest->new({
        clientID => $self->clientID//uuidgen , heartbeatInbox => $self->new_inbox
    });
    my $connect_response;
    $self->cluster_discover_subject($CLUSTER_DISCOVER_SUBJECT) unless defined $self->cluster_discover_subject;
    $self->clusterID($CLUSTER_ID) unless defined $self->clusterID;

    $self->request(
        $self->cluster_discover_subject.'.'.$self->clusterID,
        $connect_request->pack,
        sub {
            $connect_response = Net::NATS::Streaming::PB::ConnectResponse->new(shift->data);
        }
    );
    $self->wait_for_op($CONNECT_TIMEOUT);
    if(not $connect_response)
    {
        return;
    }
    $self->heartbeat_subscription($self->subscribe(
        $connect_request->heartbeatInbox,
        sub {
            $self->heartbeats_seen($self->heartbeats_seen + 1);
            $self->publish(shift->reply_to, "");
        }
    ));
    $self->connect_request($connect_request);
    $self->connect_response($connect_response);
    return 1;
}

sub _handle_subscription_response
{
    my ($self, $subject, $request) = @_;
    my $subscription_response;
    $self->request(
        $subject,
        $request->pack,
        sub {
            $subscription_response = Net::NATS::Streaming::PB::SubscriptionResponse->new(shift->data);
        }
    );
    my $heartbeats_seen = $self->heartbeats_seen;
    $self->run(sub { return 1 if defined $subscription_response or ($self->heartbeats_seen > $heartbeats_seen + 1) });
    if(not $subscription_response or $subscription_response->error)
    {
        return $subscription_response ? $subscription_response->error : 'did not receive response from server';
    }
    return $subscription_response;
}

sub subscribe_channel
{
    my ($self, $params, $sub, $manual_ack) = @_;
    my $subscription_request = Net::NATS::Streaming::PB::SubscriptionRequest->new;
    $subscription_request->copy_from({
        maxInFlight => $MAX_INFLIGHT,
        ackWaitInSecs => $ACK_WAIT,
        startPosition => exists $params->{durableName}
            ? Net::NATS::Streaming::PB::StartPosition::LastReceived
            : Net::NATS::Streaming::PB::StartPosition::NewOnly,
        %{ blessed $params ? $params->to_hashref : $params }
    });
    my $inbox = $self->new_inbox();
    $subscription_request->set_inbox($inbox);
    $subscription_request->set_clientID($self->connect_request->clientID);
    my $subscription_response = $self->_handle_subscription_response($self->connect_response->subRequests, $subscription_request);
    return $subscription_response if not blessed $subscription_response;
    my $ackInbox = $subscription_response->ackInbox;
    my $durableName = $subscription_request->durableName;
    my $subject = $subscription_request->subject;
    return $self->subscribe($inbox, sub {
        return Net::NATS::Streaming::PB::UnsubscribeRequest->new({
            inbox => $ackInbox,
            durableName => $durableName,
            subject => $subject,
            clientID => $self->connect_request->clientID
        }) unless @_;
        my $msg = Net::NATS::Streaming::PB::MsgProto->new(shift->data);
        my $ack = Net::NATS::Streaming::PB::Ack->new({
            subject  => $msg->subject,
            sequence => $msg->sequence
        });
        $sub->($msg, $ackInbox);
        $self->publish($ackInbox, $ack->pack) if not $manual_ack;
    });
}

sub ack_msg
{
    my ($self, $msg, $ackInbox) = @_;
    my $ack = Net::NATS::Streaming::PB::Ack->new({
        subject  => $msg->subject,
        sequence => $msg->sequence
    });
    $self->publish($ackInbox, $ack->pack);
}

sub unsubscribe_channel
{
    my ($self, $subscription) = @_;
    my $unsubscribe_request = $subscription->callback->();
    $self->unsubscribe($subscription);
    return $self->_handle_subscription_response($self->connect_response->unsubRequests, $unsubscribe_request);
}

my %pub_ack_handlers;
our %guids_in_flight;
my $default_ack_handler = sub {
    my $PubAck = Net::NATS::Streaming::PB::PubAck->new(shift->data);
    if($PubAck->error)
    {
        $guids_in_flight{ $PubAck->guid } = $PubAck->error;
        return;
    }
    delete $guids_in_flight{ $PubAck->guid };
};

sub publish_channel
{
    my ($self, $params, $sub) = @_;
    my $pub_msg = Net::NATS::Streaming::PB::PubMsg->new({
        (exists $params->{guid} ? () : (guid => uuidgen())),
        clientID => $self->connect_request->clientID,
        %{ blessed $params ? $params->to_hashref : $params },
    });
    if($PUB_NOACK)
    {
        return $self->publish(
            $self->connect_response->pubPrefix.'.'.$pub_msg->subject,
            $pub_msg->pack
        );
    }
    if($sub and not exists $pub_ack_handlers{ $sub })
    {
        my $inbox = $self->new_inbox();
        my $subsciption = $self->subscribe($inbox, sub {
            my $PubAck = Net::NATS::Streaming::PB::PubAck->new(shift->data);
            $sub->($PubAck);
            delete $guids_in_flight{ $PubAck->guid } if not $PubAck->error;
        });
        $pub_ack_handlers{$sub} = [$subsciption, $inbox];
    }
    elsif(not $sub and not exists $pub_ack_handlers{ $default_ack_handler })
    {
        my $inbox = $self->new_inbox();
        my $subsciption = $self->subscribe($inbox, $default_ack_handler);
        $pub_ack_handlers{$default_ack_handler} = [$subsciption, $inbox];
    }
    if(keys %guids_in_flight > $MAX_PUB_ACKS_INFLIGHT)
    {
        return "publish_channel error: too many outstanding Acks";
    }
    else
    {
        $guids_in_flight{ $pub_msg->guid } = 'no ack';
    }
    $self->publish(
        $self->connect_response->pubPrefix.'.'.$pub_msg->subject,
        $pub_msg->pack,
        $sub ? $pub_ack_handlers{$sub}[1] : $pub_ack_handlers{$default_ack_handler}[1]
    );
    if(not $sub)
    {
        my $heartbeats_seen = $self->heartbeats_seen;
        $self->run(sub {
            return 1 if not exists $guids_in_flight{ $pub_msg->guid } or $guids_in_flight{ $pub_msg->guid } ne 'no ack';
            return 1 if $self->heartbeats_seen > $heartbeats_seen + 1;
        });
        if(exists $guids_in_flight{ $pub_msg->guid })
        {
            return "publish_channel error: can't publish "
                    .$pub_msg->guid
                    .' :'
                    .$guids_in_flight{ $pub_msg->guid };
        }
    }
    return;
}

sub close_stream
{
    my $self = shift;
    my $close_response;
    $self->request(
        $self->connect_response->closeRequests,
        Net::NATS::Streaming::PB::CloseRequest->new({
            clientID => $self->connect_request->clientID
        })->pack,
        sub { $close_response = Net::NATS::Streaming::PB::CloseResponse->new(shift->data); }
    );
    while($self->wait_for_op($CONNECT_TIMEOUT))
    {
        last if defined $close_response;
    }
    for my $sub (keys %pub_ack_handlers)
    {
        $pub_ack_handlers{$sub}[0]->unsubscribe;
        delete $pub_ack_handlers{$sub};
    }
    $self->heartbeat_subscription->unsubscribe;
    $self->heartbeat_subscription(undef);
    return $close_response ? $close_response->error : 'failed to close stream';
}

sub close
{
    my $self = shift;
    my $ret = $self->close_stream;
    $self->SUPER::close();
    return $ret;
}

sub run
{
    my ($self, $sub, $timeout) = @_;
    while($self->wait_for_op($timeout//$WAIT_FOR_OP_TIMEOUT))
    {
        last if $sub and $sub->();
    }
}

1;

__END__

=head1 NAME

Net::NATS::Streaming::Client - A Perl client for the NATS Streaming messaging system.

=head1 SYNOPSIS

  #
  # Basic Usage
  #
  This class is a subclass of Net::NATS::Client and delegates all networking
  to the parent.

  $client = Net::NATS::Streaming::Client->new(uri => 'nats://localhost:4222', clientID => 'test_client', clusterID => 'test-cluster');
  $client->connect() or die $!;

  # Simple Async Subscriber
  $subscription = $client->subscribe_channel({ subject => 'foo' }, sub {
      my ($message) = @_;
      printf("Received a message: %s\n", $message->data);
  });
  $self->run;

  # Simple Publisher
  $client->publish_channel({ subject => 'foo', data => 'Hello, World!'});

  # Unsubscribe
  $client->unsubscribe_channel($subscription);

  # Close stream
  $client->close_stream();

=head1 REPOSITORY

L<https://github.com/sergeykolychev/perl-nats-streaming>

=head1 SEE ALSO

L<https://github.com/carwynmoore/perl-nats>
Net::NATS::Client

=head1 AUTHOR

    Sergey Kolychev, <sergeykolychev.github@gmail.com>

=head1 COPYRIGHT & LICENSE

    Copyright (C) 2017 by Sergey Kolychev <sergeykolychev.github@gmail.com>

    This library is licensed under Apache 2.0 license https://www.apache.org/licenses/LICENSE-2.0

=cut
