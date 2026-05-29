package Net::STOMP::Client::Wrapper;
use strict;
use warnings;
use base qw{Package::New};
use Net::STOMP::Client;
use Net::RabbitMQ::Management::API;
use URL::Encode qw{url_encode};

our $VERSION = '0.03';

=head1 NAME

Net::STOMP::Client::Wrapper - Stomp Client and RabbitMQ Management API wrapper

=head1 SYNOPSIS

Producer

  use Net::STOMP::Client::Wrapper;
  my $wrapper = Net::STOMP::Client::Wrapper->new(queue_name=>"my_queue");   #ISA Net::STOMP::Client::Wrapper
  my $stomp   = $wrapper->stomp_connect;                                    #ISA Net::STOMP::Client connected
  $wrapper->send(body=>"my_payload");

Consumer

  use Net::STOMP::Client::Wrapper;
  my $wrapper = Net::STOMP::Client::Wrapper->new(queue_name=>"my_queue");   #ISA Net::STOMP::Client::Wrapper
  my $stomp   = $wrapper->stomp_connect_subscribe;                          #ISA Net::STOMP::Client subscribed to queue
  $stomp->wait_for_frames(callback => \&queue_callback);

Monitor

  use Net::STOMP::Client::Wrapper;
  my $wrapper   =  Net::STOMP::Client::Wrapper->new(queue_name=>"my_queue"); #ISA Net::STOMP::Client::Wrapper
  my $result    = $wrapper->management_api_get_queue;                       #ISA Net::RabbitMQ::Management::API::Result
  my $content   = $result->content;                                         #ISA HASH
  my $consumers = $content->{'consumers'} || 0;
  my $messages  = $content->{'messages'}  || 0;
  printf "Consumers: %s, Messages: %s\n", $consumers, $messages;

Super Class

  package My::Wrapper;
  use base qw{Net::STOMP::Client::Wrapper};
  sub host {"my_host"};
  sub queue_name {"my_queue"};

=head1 DESCRIPTION

Net::STOMP::Client::Wrapper is a wrapper of L<Net::STOMP::Client> and L<Net::RabbitMQ::Management::API> with sane defaults.

This package is a wrapper for my typical use case which is a single RabbitMQ server with the Stomp and Management API plugins enabled and a single queue_name.

  sudo yum install rabbitmq-server
  sudo /usr/lib/rabbitmq/bin/rabbitmq-plugins enable rabbitmq_stomp
  sudo /usr/lib/rabbitmq/bin/rabbitmq-plugins enable rabbitmq_management
  sudo systemctl enable rabbitmq-server
  sudo systemctl start rabbitmq-server

=head1 Properties

=head2 host

Default: 127.0.0.1

=cut

sub host {
  my $self        = shift;
  $self->{'host'} = shift if @_;
  $self->{'host'} = '127.0.0.1' unless $self->{'host'};
  return $self->{'host'};
}

=head2 port

Default: 61613

=cut

sub port {
  my $self        = shift;
  $self->{'port'} = shift if @_;
  $self->{'port'} = '61613' unless $self->{'port'};
  return $self->{'port'};
}

=head2 login

Default: guest

=cut

sub login {
  my $self         = shift;
  $self->{'login'} = shift if @_;
  $self->{'login'} = 'guest' unless $self->{'login'};
  return $self->{'login'};
}

=head2 passcode

Default: guest

=cut

sub passcode {
  my $self            = shift;
  $self->{'passcode'} = shift if @_;
  $self->{'passcode'} = 'guest' unless $self->{'passcode'};
  return $self->{'passcode'};
}

=head2 vhost, vhost_url_encoded

Default: /

=cut

sub vhost {
  my $self         = shift;
  $self->{'vhost'} = shift if @_;
  $self->{'vhost'} = '/' unless $self->{'vhost'};
  return $self->{'vhost'};
}

sub vhost_url_encoded {url_encode(shift->vhost)};

=head2 queue_name, destination

Returns the short queue_name or the formatted destination.

  $wrapper->queue_name("my_queue")
  my $queue_name  = $wrapper->queue_name;
  my $destination = $wrapper->destination; #ISA string formatted as "/queue/{queue_name}"

Default: ''

=cut

sub queue_name {
  my $self              = shift;
  $self->{'queue_name'} = shift if @_;
  $self->{'queue_name'} = '' unless defined $self->{'queue_name'};
  return $self->{'queue_name'};
}

sub destination {join('/', '/queue', shift->queue_name)};

=head2 subscribe_id

Default: {uuid}

=cut

sub subscribe_id {
  my $self                = shift;
  $self->{'subscribe_id'} = shift if @_;
  $self->{'subscribe_id'} = $self->stomp->uuid unless $self->{'subscribe_id'};
  return $self->{'subscribe_id'};
}

=head2 subscribe_ack

Default: client

=cut

sub subscribe_ack {
  my $self                 = shift;
  $self->{'subscribe_ack'} = shift if @_;
  $self->{'subscribe_ack'} = 'client' unless $self->{'subscribe_ack'};
  return $self->{'subscribe_ack'};
}

=head2 subscribe_prefetch_count

Default: 1

=cut

sub subscribe_prefetch_count {
  my $self                            = shift;
  $self->{'subscribe_prefetch_count'} = shift if @_;
  $self->{'subscribe_prefetch_count'} = 1 unless $self->{'subscribe_prefetch_count'};
  return $self->{'subscribe_prefetch_count'};
}

our $MANAGEMENT_API_PROTOCOL = 'http';
our $MANAGEMENT_API_PORT     = '15672';
our $MANAGEMENT_API_PATH     = '/api';

=head2 management_api_url

Default: http://{host}:15672/api

=cut

sub management_api_url {
  my $self                      = shift;
  $self->{'management_api_url'} = shift if @_;
  $self->{'management_api_url'} = sprintf('%s://%s:%s%s', $MANAGEMENT_API_PROTOCOL, $self->host, $MANAGEMENT_API_PORT, $MANAGEMENT_API_PATH) unless $self->{'management_api_url'};
  return $self->{'management_api_url'};
}

=head1 Methods

=head2 send

Wrapper around `stomp->send` with default destination

  $wrapper->send(body=>"my_string"); #destination is defaulted to $wrapper->destination;
  $wrapper->send(destination=>"/queue/another_queue", body=>"my_string");

Note: stomp must be connected before calling send.

=cut

sub send {
  my $self               = shift;
  my %data               = @_;
  $data{'destination'} ||= $self->destination;
  return $self->stomp->send(%data);
}

=head2 management_api_get_queue

Returns a L<Net::RabbitMQ::Management::API::Result> object

=cut

sub management_api_get_queue {
  my $self = shift;
  return $self->management_api->get_queue(name => $self->queue_name, vhost => $self->vhost_url_encoded); #ISA Net::RabbitMQ::Management::API::Result
}

=head1 Object Accessors

=head2 stomp_connect_subscribe

Returns a L<Net::STOMP::Client> object connection and subscribed to the configured queue

  my $stomp = $wrapper->stomp_connect_subscribe;

Limitations: Only Call once!

=cut

sub stomp_connect_subscribe {
  my $self  = shift;
  my $stomp = $self->stomp_connect;
  die("Error: queue_name required") unless $self->queue_name;
  my %data  = (
               'destination'    => $self->destination,
               'id'             => $self->subscribe_id,
               'ack'            => $self->subscribe_ack,
               'prefetch-count' => $self->subscribe_prefetch_count,
              );
  $stomp->subscribe(%data);
  my $subscriptions = $self->{'__subscriptions'} ||= []; #cache for stomp_disconnect
  push @$subscriptions, \%data;
  return $stomp;
}

=head2 stomp_connect

Returns a connected L<Net::STOMP::Client> object.

  my $stomp = $wrapper->stomp_connect;

Limitations: Only Call once!

=cut

sub stomp_connect {
  my $self  = shift;
  my $stomp = $self->stomp;
  $stomp->connect(login => $self->login, passcode => $self->passcode, host => $self->vhost);
  return $stomp;
}

=head2 stomp_disconnect

Unsubscribes to any subscriptions and disconnects stomp client.

=cut

sub stomp_disconnect {
  my $self          = shift;
  my $stomp         = $self->stomp;
  my $subscriptions = $self->{'__subscriptions'} || [];
  while (@$subscriptions) {
    my $subscription = pop @$subscriptions;
    my $id           = $subscription->{'id'};
    $stomp->unsubscribe(id => $id);
  }
  return $stomp->disconnect;
}

=head2 stomp

Returns the cached L<Net::STOMP::Client> object

=cut

sub stomp {
  my $self         = shift;
  $self->{'stomp'} = shift if @_;
  $self->{'stomp'} = Net::STOMP::Client->new(host => $self->host, port => $self->port) unless $self->{'stomp'};
  return $self->{'stomp'};
}

=head2 management_api

Returns a L<Net::RabbitMQ::Management::API> object

=cut

sub management_api {
  my $self                  = shift;
  $self->{'management_api'} = shift if @_;
  $self->{'management_api'} = Net::RabbitMQ::Management::API->new(url => $self->management_api_url) unless $self->{'management_api'};
  return $self->{'management_api'};
}

=head1 SEE ALSO

L<Net::STOMP::Client>, L<Net::RabbitMQ::Management::API>

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by Michael Davis

LICENSE: MIT

=cut

1;
