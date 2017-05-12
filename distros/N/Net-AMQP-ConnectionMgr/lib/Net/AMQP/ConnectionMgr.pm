package Net::AMQP::ConnectionMgr;
use strict;
use warnings;

our $VERSION = '0.0.1';

sub new {
    my $self = shift;
    my $class = ref($self) || $self;
    my $hostname = shift || 'localhost';
    my $options = shift || {};
    my $conn_class = shift || 'Net::AMQP::RabbitMQ';
    return bless
      { hostname => $hostname,
        options => $options,
        conn_class => $conn_class,
      }, $class;
}

sub _rmq_connect {
    my $self = shift;
    if (!$self->{conn_class}->can('new')) {
        eval "require $self->{conn_class}";
        if ($@) {
            die "Failed to load $self->{conn_class}: $@"
        }
    }
    $self->{rmq} = $self->{conn_class}->new();
    $self->{rmq}->connect($self->{hostname}, $self->{options});
    # we only need to run channel declarations, because resource
    # declarations get a specific channel which runs them
    $self->_run_channel_declarations();
}

sub _run_channel_declarations {
    my $self = shift;

    if (!$self->{declare_channel_data}) {
        $self->{declare_channel_data} = [];
    }
    my $data = $self->{declare_channel_data};
    my $channel_count = 0;
    for my $code (@$data) {
        $channel_count++;
        $self->{rmq}->channel_open($channel_count);
        $code->($self->{rmq}, $channel_count);
    }
}

sub with_connection_do {
    my ($self, $code, $retry) = @_;
    $retry ||= 1;
    while ($retry >= 0) {
        eval {
            if (!$self->{rmq} || !$self->{rmq}->is_connected()) {
                $self->_rmq_connect();
            }
            $code->($self->{rmq});
        };
        if (!$@) {
            last;
        } else {
            $retry--;
        }
    }
    if ($@) {
        die $@;
    }
}

sub declare_channel {
    my ($self, $code) = @_;
    if (!$self->{declare_channel_data}) {
        $self->{declare_channel_data} = [];
    }
    my $data = $self->{declare_channel_data};
    my $next_channel = scalar(@$data) + 1;

    # we put a placeholder first, such that we don't get ourselves
    # into a bad position in case this code fails.
    $data->[$next_channel - 1] = sub { 1; };

    my $rmq = $self->{rmq};
    if ($rmq && $rmq->is_connected()) {
        $self->with_connection_do(sub { $rmq->channel_open($next_channel);
                                        $code->($rmq, $next_channel) });
    }

    # if we got here, then we assign
    $data->[$next_channel - 1] = $code;
    return $next_channel;
}

sub declare_resource {
    my ($self, $code) = @_;
    if (!$self->{declare_resouce_data}) {
        $self->{declare_resouce_data} = [];
    }
    my $data = $self->{declare_resource_data};
    if (!$self->{declare_resource_channel}) {
        $self->{declare_resource_channel} =
          $self->declare_channel(sub { $_->(@_) for @$data } );
    }
    my $decl_ch = $self->{declare_resource_channel};
    if ($self->{rmq} && $self->{rmq}->is_connected()) {
        $self->with_connection_do(sub { $code->($_[0], $decl_ch) });
    }
    push @$data, $code;
    return 1;
}

1;

__END__

=head1 NAME

Net::AMQP::ConnectionMgr - Manages a AMQP connection

=head1 SYNOPSIS

  my $cmgr = Net::AMQP::ConnectionMgr->new('localhost', { });
  my $channel = $cmgr->declare_channel
    (sub {
        my ($rmq, $channel) = @_;
        my %exchange_options =
          ( exchange_type => 'topic',
            passive       => 0,
            durable       => 1,
            auto_delete   => 0,
          );
        $rmq->exchange_declare
          ($channel, $exchange_name,
           \%exchange_options, {});
    });
  $cmgr->with_connection_do
    (sub {
       my $rmq = shift;
       $rmq->publish($channel, $routing_key, $body,
                     \%message_options,
                     \%message_props)
     });


=head1 DESCRIPTION

Usage of rabbitmq has two common expectations from the application
developer:

=over

=item

The connection is subject to being closed from the server at any
point, and the application should handle that disconnect gracefully.

=item

The applications should always declare the resources they use for
every connection.

=back

Complying to that expectation using only Net::AMQP::RabbitMQ is very
error-prone. This modules provides a simple way of handling it.

=head1 METHODS

=over

=item new($hostname, $options, $conn_class = Net::AMQP::RabbitMQ)

Initialize the object with the options. Does not necessarily start the
connection right away, but will transparently connect when needed. The
arguments to new are the same arguments for
Net::AMQP::RabbitMQ->connect.

The last argument is to allow you to dependency-inject a different
implementation for testing purposes or for using an alternative
implmentation.

=item with_connection_do($code, $retry = 1)

This will wrap the given coderef and execute it with the connection as
the first argument. This will also run the code within an eval and
catch rabbitmq errors and will automatically re-connect and re-execute
the code if the code dies.

The code, however, will only try that as many times as $retry_count
(which defaults to 1).

Note: This function doesn't pass any extra arguments. The point of it
is that you should use a closure to access any other data that you
need.

=item declare_channel($init_code)

Returns a new channel number in the rabbitmq connection.

It will call channel_open for you.

The argument is a code ref to additional setup that is necessary for
this channel, such as "consume" requests.

If the connection is open, the init_code will be executed right away.
Otherwise it will be deferred to when the connection is actually
established.

The init_code ref will be called again in case there is a re-connect.

The arguments to the coderef will be the connection and the channel
number.

=item declare_resource($init_code)

Adds a resource declaration to this connection.

If the connection is open, the init_code will be executed right away.
Otherwise it will be deferred to when the connection is actually
established.

The init_code ref will be called again in case there is a re-connect.

The arguments to the coderef will be the connection and the channel
number.

=back

=head1 COPYRIGHT

Copyright 2016 Bloomberg Finance L.P.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut
