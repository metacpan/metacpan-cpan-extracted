package Net::Async::Redis;
# ABSTRACT: Redis support for IO::Async
use strict;
use warnings;

use parent qw(Net::Async::Redis::Commands IO::Async::Notifier);

our $VERSION = '1.011';

=head1 NAME

Net::Async::Redis - talk to Redis servers via L<IO::Async>

=head1 SYNOPSIS

    use Net::Async::Redis;
    use IO::Async::Loop;
    my $loop = IO::Async::Loop->new;
    $loop->add(my $redis = Net::Async::Redis->new);
    $redis->connect->then(sub {
        $redis->get('some_key')
    })->then(sub {
        my $value = shift;
        return Future->done($value) if $value;
        $redis->set(some_key => 'some_value')
    })->on_done(sub {
        print "Value: " . shift;
    })->get;

    # ... or with Future::AsyncAwait
    await $redis->connect;
    my $value = await $redis->get('some_key');
    $value ||= await $redis->set(some_key => 'some_value');
    print "Value: $value";

=head1 DESCRIPTION

See L<Net::Async::Redis::Commands> for the full list of commands.

=cut

use mro;
use Class::Method::Modifiers;
use curry::weak;
use IO::Async::Stream;
use Ryu::Async;
use URI;
use URI::redis;

use Log::Any qw($log);

use List::Util qw(pairmap);

use Net::Async::Redis::Multi;
use Net::Async::Redis::Subscription;
use Net::Async::Redis::Subscription::Message;

=head1 METHODS

B<NOTE>: For a full list of the Redis methods supported by this module,
please see L<Net::Async::Redis::Commands>.

=cut

=head1 METHODS - Subscriptions

See L<https://redis.io/topics/pubsub> for more details on this topic.
There's also more details on the internal implementation in Redis here:
L<https://making.pusher.com/redis-pubsub-under-the-hood/>.

=cut

=head2 psubscribe

Subscribes to a pattern.

=cut

sub psubscribe {
    my ($self, $pattern) = @_;
    return $self->next::method($pattern)
        ->then(sub {
            $self->{pubsub} //= 0;
            $self->{pending_subscription_pattern_channel}{$pattern} //= $self->future('pattern_subscription[' . $pattern . ']');
        })->then(sub {
            Future->done(
                $self->{subscription_pattern_channel}{$pattern} //= Net::Async::Redis::Subscription->new(
                    redis   => $self,
                    channel => $pattern
                )
            );
        })
}

=head2 subscribe

Subscribes to one or more channels.

Resolves to a L<Net::Async::Redis::Subscription> instance.

Example:

 # Subscribe to 'notifications' channel,
 # print the first 5 messages, then unsubscribe
 $redis->subscribe('notifications')
    ->then(sub {
        my $sub = shift;
        $sub->map('payload')
            ->take(5)
            ->say
            ->completion
    })->then(sub {
        $redis->unsubscribe('notifications')
    })->get

=cut

sub subscribe {
    my ($self, @channels) = @_;
    $self->next::method(@channels)
        ->then(sub {
            $log->tracef('Marking as pubsub mode');
            $self->{pubsub} //= 0;
            Future->wait_all(
                map {
                    $self->{pending_subscription_channel}{$_} //= $self->future('subscription[' . $_ . ']')
                } @channels
            )
        })->then(sub {
            Future->done(
                @{$self->{subscription_channel}}{@channels}
            )
        })
}

=head1 METHODS - Transactions

=head2 multi

Executes the given code in a Redis C<MULTI> transaction.

This will cause each of the requests to be queued, then executed in a single atomic transaction.

Example:

 $redis->multi(sub {
  my $tx = shift;
  $tx->incr('some::key')->on_done(sub { print "Final value for incremented key was " . shift . "\n"; });
  $tx->set('other::key => 'test data')
 })->then(sub {
  my ($success, $failure) = @_;
  return Future->fail("Had $failure failures, expecting everything to succeed") if $failure;
  print "$success succeeded\m";
  return Future->done;
 })->retain;

=cut

sub multi {
    use Scalar::Util qw(reftype);
    use namespace::clean qw(reftype);
    my ($self, $code) = @_;
    die 'Need a coderef' unless $code and reftype($code) eq 'CODE';
    my $multi = Net::Async::Redis::Multi->new(
        redis => $self,
    );
    my $task = sub {
        local $self->{_is_multi} = 1;
        Net::Async::Redis::Commands::multi(
            $self
        )->then(sub {
            $multi->exec($code)
        })
    };
    my @pending = @{$self->{pending_multi}};

    $log->tracef('Have %d pending MULTI transactions', 
        0 + @pending
    );
    push @{$self->{pending_multi}}, $self->loop->new_future;
    return $task->() unless @pending;
    return Future->wait_all(
        @pending
    )->then($task);
}

around [qw(discard exec)] => sub {
    my ($code, $self, @args) = @_;
    local $self->{_is_multi} = 1;
    my $f = $self->$code(@args);
    (shift @{$self->{pending_multi}})->done;
    $f
};

=head1 METHODS - Generic

=head2 keys

=cut

sub keys : method {
    my ($self, $match) = @_;
    $match //= '*';
    return $self->next::method($match);
}

=head2 watch_keyspace

=cut

sub watch_keyspace {
    my ($self, $pattern, $code) = @_;
    $pattern //= '*';
    my $sub = '__keyspace@*__:' . $pattern;
    (
        $self->{have_notify} ||= $self->config_set(
            'notify-keyspace-events', 'Kg$xe'
        )
    )->then(sub {
        $self->psubscribe($sub)
    })->on_done(sub {
        shift->events
            ->each(sub {
                my $data = $_;
                return unless $data eq $sub;
                my ($k, $op) = map $_->{data}, @{$data->{data}}[2, 3];
                $k =~ s/^[^:]+://;
                $code->($op => $k);
            })
    })->retain
}

sub endpoint { shift->{endpoint} }

sub local_endpoint { shift->{local_endpoint} }

=head2 connect

=cut

sub connect : method {
    my ($self, %args) = @_;
    $self->configure(%args) if %args;
    my $uri = $self->uri->clone;
    for (qw(host port)) {
        $uri->$_($self->$_) if defined $self->$_;
    }
    my $auth = $self->{auth};
    $auth //= ($uri->userinfo =~ s{^[^:]*:}{}r) if defined $uri->userinfo;
    $self->{connection} //= $self->loop->connect(
        service => $uri->port // 6379,
        host    => $uri->host,
        socktype => 'stream',
    )->then(sub {
        my ($sock) = @_;
        $self->{endpoint} = join ':', $sock->peerhost, $sock->peerport;
        $self->{local_endpoint} = join ':', $sock->sockhost, $sock->sockport;
        my $proto = $self->protocol;
        my $stream = IO::Async::Stream->new(
            handle    => $sock,
            on_closed => $self->curry::weak::notify_close,
            on_read   => sub {
                $proto->parse($_[1]);
                0
            }
        );
        $self->add_child($stream);
        Scalar::Util::weaken(
            $self->{stream} = $stream
        );
        return $self->auth($auth) if defined $auth;
        return Future->done;
    })->on_fail(sub { delete $self->{connection} });
}

sub connected { shift->connect }

=head2 on_message

Called for each incoming message.

Passes off the work to L</handle_pubsub_message> or the next queue
item, depending on whether we're dealing with subscriptions at the moment.

=cut

sub on_message {
    my ($self, $data) = @_;
    local @{$log->{context}}{qw(redis_remote redis_local)} = ($self->endpoint, $self->local_endpoint);
    $log->tracef('Incoming message: %s', $data);
    return $self->handle_pubsub_message(@$data) if exists $self->{pubsub};

    my $next = shift @{$self->{pending}} or die "No pending handler";
    $next->[1]->done($data);
}

sub on_error_message {
    my ($self, $data) = @_;
    local @{$log->{context}}{qw(redis_remote redis_local)} = ($self->endpoint, $self->local_endpoint);
    $log->tracef('Incoming error message: %s', $data);

    my $next = shift @{$self->{pending}} or die "No pending handler";
    $next->[1]->fail($data);
}

sub handle_pubsub_message {
    my ($self, $type, @details) = @_;
    $type = lc $type;
    if($type eq 'message') {
        my ($channel, $payload) = @details;
        if(my $sub = $self->{subscription_channel}{$channel}) {
            my $msg = Net::Async::Redis::Subscription::Message->new(
                type         => $type,
                channel      => $channel,
                payload      => $payload,
                redis        => $self,
                subscription => $sub
            );
            $sub->events->emit($msg);
        } else {
            $log->warnf('Have message for unknown channel [%s]', $channel);
        }
        $self->bus->invoke_event(message => [ $type, $channel, $payload ]) if exists $self->{bus};
        return;
    }
    if($type eq 'pmessage') {
        my ($pattern, $channel, $payload) = @details;
        if(my $sub = $self->{subscription_pattern_channel}{$pattern}) {
            my $msg = Net::Async::Redis::Subscription::Message->new(
                type         => $type,
                pattern      => $pattern,
                channel      => $channel,
                payload      => $payload,
                redis        => $self,
                subscription => $sub
            );
            $sub->events->emit($msg);
        } else {
            $log->warnf('Have message for unknown channel [%s]', $channel);
        }
        $self->bus->invoke_event(message => [ $type, $channel, $payload ]) if exists $self->{bus};
        return;
    }

    my ($channel, $payload) = @details;
    my $k = (substr $type, 0, 1) eq 'p' ? 'subscription_pattern_channel' : 'subscription_channel';
    if($type =~ /unsubscribe$/) {
        --$self->{pubsub};
        if(my $sub = delete $self->{$k}{$channel}) {
            $log->tracef('Removed subscription for [%s]', $channel);
        } else {
            $log->warnf('Have unsubscription for unknown channel [%s]', $channel);
        }
    } elsif($type =~ /subscribe$/) {
        $log->tracef('Have %s subscription for [%s]', (exists $self->{$k}{$channel} ? 'existing' : 'new'), $channel);
        ++$self->{pubsub};
        $self->{$k}{$channel} //= Net::Async::Redis::Subscription->new(
            redis => $self,
            channel => $channel
        );
        $self->{'pending_' . $k}{$channel}->done($payload) unless $self->{'pending_' . $k}{$channel}->is_done;
    } else {
        $log->warnf('have unknown pubsub message type %s with channel %s payload %s', $type, $channel, $payload);
    }
}

=head2 stream

Represents the L<IO::Async::Stream> instance for the active Redis connection.

=cut

sub stream { shift->{stream} }

=head2 pipeline_depth

Number of requests awaiting responses before we start queuing.
This defaults to an arbitrary value of 100 requests.

Note that this does not apply when in L<transaction|METHODS - Transactions> (C<MULTI>) mode.

See L<https://redis.io/topics/pipelining> for more details on this concept.

=cut

sub pipeline_depth { shift->{pipeline_depth} //= 100 }

=head1 METHODS - Deprecated

This are still supported, but no longer recommended.

=cut

sub bus {
    shift->{bus} //= do {
        require Mixin::Event::Dispatch::Bus;
        Mixin::Event::Dispatch::Bus->VERSION(2.000);
        Mixin::Event::Dispatch::Bus->new
    }
}

=head1 METHODS - Internal

=cut

sub notify_close {
    my ($self) = @_;
    # If we think we have an existing connection, it needs removing:
    # there's no guarantee that it's in a usable state.
    if(my $stream = delete $self->{stream}) {
        $stream->close_now;
    }

    # Also clear our connection future so that the next request is triggered appropriately
    delete $self->{connection};
    # Clear out anything in the pending queue - we normally wouldn't expect anything to
    # have ready status here, but no sense failing on a failure.
    !$_->[1]->is_ready && $_->[1]->fail('Server connection is no longer active', redis => 'disconnected') for splice @{$self->{pending}};

    # Subscriptions also need clearing up
    $_->cancel for values %{$self->{subscription_channel}};
    $self->{subscription_channel} = {};
    $_->cancel for values %{$self->{subscription_pattern_channel}};
    $self->{subscription_pattern_channel} = {};

    $self->maybe_invoke_event(disconnect => );
}

sub command_label {
    my ($self, @cmd) = @_;
    return join ' ', @cmd if $cmd[0] eq 'KEYS';
    return $cmd[0];
}

our %ALLOWED_SUBSCRIPTION_COMMANDS = (
    SUBSCRIBE    => 1,
    PSUBSCRIBE   => 1,
    UNSUBSCRIBE  => 1,
    PUNSUBSCRIBE => 1,
    PING         => 1,
    QUIT         => 1,
);

sub execute_command {
    my ($self, @cmd) = @_;

    # First, the rules: pubsub or plain
    my $is_sub_command = exists $ALLOWED_SUBSCRIPTION_COMMANDS{$cmd[0]};
    return Future->fail(
        'Currently in pubsub mode, cannot send regular commands until unsubscribed',
        redis =>
            0 + (keys %{$self->{subscription_channel}}),
            0 + (keys %{$self->{subscription_pattern_channel}})
    ) if exists $self->{pubsub} and not $is_sub_command;

    my $f = $self->loop->new_future->set_label($self->command_label(@cmd));
    $log->tracef("Will have to wait for %d MULTI tx", 0 + @{$self->{pending_multi}}) unless $self->{_is_multi};
    my $code = sub {
        local @{$log->{context}}{qw(redis_remote redis_local)} = ($self->endpoint, $self->local_endpoint);
        my $cmd = join ' ', @cmd;
        $log->tracef('Outgoing [%s]', $cmd);
        push @{$self->{pending}}, [ $cmd, $f ];
        $log->tracef("Pipeline depth now %d", 0 + @{$self->{pending}});
        $self->stream->write(
            $self->protocol->encode_from_client(@cmd)
        )->then(sub {
            $f->done if $is_sub_command;
            $f
        })
    };
    return $code->() if $self->{stream} and ($self->{is_multi} or 0 == @{$self->{pending_multi}});
    return (
        $self->{_is_multi}
        ? $self->connected
        : Future->wait_all(
            $self->connected,
            @{$self->{pending_multi}}
        )
    )->then($code);
}

sub ryu {
    my ($self) = @_;
    $self->{ryu} ||= do {
        $self->add_child(
            my $ryu = Ryu::Async->new
        );
        $ryu
    }
}

sub future {
    my ($self) = @_;
    return $self->loop->new_future(@_);
}

sub protocol {
    my ($self) = @_;
    $self->{protocol} ||= do {
        require Net::Async::Redis::Protocol;
        Net::Async::Redis::Protocol->new(
            handler => $self->curry::weak::on_message,
            error   => $self->curry::weak::on_error_message,
        )
    };
}

sub host { shift->{host} }
sub port { shift->{port} }
sub uri { shift->{uri} //= URI->new('redis://localhost') }

sub configure {
    my ($self, %args) = @_;
    $self->{pending_multi} //= [];
    for (qw(host port auth uri pipeline_depth)) {
        $self->{$_} = delete $args{$_} if exists $args{$_};
    }
    $self->{uri} = URI->new($self->{uri}) unless ref $self->uri;
    $self->next::method(%args)
}

1;

__END__

=head1 SEE ALSO

Some other Redis implementations on CPAN:

=over 4

=item * L<Mojo::Redis2> - nonblocking, using the L<Mojolicious> framework, actively maintained

=item * L<MojoX::Redis>

=item * L<RedisDB>

=item * L<Cache::Redis>

=item * L<Redis::Fast>

=item * L<Redis::Jet>

=back

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>, with patches and input from
C<< BINARY@cpan.org >>, C<< PEVANS@cpan.org >> and C<< @eyadof >>.

=head1 LICENSE

Copyright Tom Molesworth and others 2015-2018.
Licensed under the same terms as Perl itself.

