package Net::Async::Redis;
# ABSTRACT: Redis support for IO::Async
use strict;
use warnings;

use parent qw(Net::Async::Redis::Commands IO::Async::Notifier);

our $VERSION = '1.002';

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

=head1 DESCRIPTION

See L<Net::Async::Redis::Commands> for the full list of commands.

=cut

use mro;
use curry::weak;
use IO::Async::Stream;
use Ryu::Async;

use Log::Any qw($log);

use List::Util qw(pairmap);

use Net::Async::Redis::Multi;
use Net::Async::Redis::Subscription;
use Net::Async::Redis::Subscription::Message;

=head1 METHODS

B<NOTE>: For a full list of Redis methods, please see L<Net::Async::Redis::Commands>.

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
	return $self->execute_command(
		PSUBSCRIBE => $pattern
	)->then(sub {
        $self->{pubsub} = 1;
        Future->done(
            $self->{subscription_pattern_channel}{$pattern} //= Net::Async::Redis::Subscription->new(
                redis => $self,
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
            $self->{pubsub} = 1;
            my @subs = map {
                $self->{subscription_channel}{$_} //= Net::Async::Redis::Subscription->new(
                    redis => $self,
                    channel => $_
                )
            } @channels;
            Future->done(@subs);
        })
}

=head1 METHODS - Transactions



=cut

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
 });

=cut

sub multi {
    use Scalar::Util qw(reftype);
    use namespace::clean qw(reftype);
    my ($self, $code) = @_;
    die 'Need a coderef' unless $code and reftype($code) eq 'CODE';
    my $multi = Net::Async::Redis::Multi->new(
        redis => $self,
    );
    $self->next::method
        ->then(sub {
            $multi->exec($code)
        })
}

sub keys : method {
	my ($self, $match) = @_;
	$match //= '*';
    return $self->next::method($match);
}

sub watch_keyspace {
	my ($self, $pattern, $code) = @_;
	$pattern //= '*';
	my $sub = '__keyspace@*__:' . $pattern;
	(
        $self->{have_notify} ||= $self->config_set(
            'notify-keyspace-events', 'Kg$xe'
        )
    )->then(sub {
		$self->bus->subscribe_to_event(
			message => sub {
				my ($ev, $data) = @_;
				return unless $data->{data}[1]{data} eq $sub;
				my ($k, $op) = map $_->{data}, @{$data->{data}}[2, 3];
				$k =~ s/^[^:]+://;
				$code->($op => $k);
			}
		);
		$self->psubscribe($sub)
	})
}

=head2 connect

=cut

sub connect {
	my ($self, %args) = @_;
	my $auth = delete $args{auth};
	$args{host} //= 'localhost';
	$args{port} //= 6379;
	$self->{connection} //= $self->loop->connect(
		service => $args{port},
		host    => $args{host},
		socktype => 'stream',
	)->then(sub {
		my ($sock) = @_;
		my $stream = IO::Async::Stream->new(
			handle    => $sock,
			on_closed => $self->curry::weak::notify_close,
			on_read   => sub {
				my ($stream, $buffref, $eof) = @_;
				$self->protocol->parse($buffref);
				0
			}
		);
		Scalar::Util::weaken(
			$self->{stream} = $stream
		);
		$self->add_child($stream);
		if(defined $auth) {
			return $self->auth($auth)
		} else {
			return Future->done
		}
	})
}

=head2 on_message

Called for each incoming message.

=cut

sub on_message {
	my ($self, $data) = @_;
	if($self->{pubsub}) {
        my ($type, $channel, $payload) = @$data;
        if($type =~ /message$/) {
            if($type eq 'message') {
                if(my $sub = $self->{subscription_channel}{$channel}) {
                    my $msg = Net::Async::Redis::Subscription::Message->new(
                        type => $type,
                        channel => $channel,
                        payload => $payload,
                        redis   => $self,
                        subscription => $sub
                    );
                    $sub->events->emit($msg);
                } else {
                    $log->errorf('Have message for unknown channel [%s]', $channel);
                }
            } elsif($type eq 'pmessage') {
                if(my $sub = $self->{subscription_pattern_channel}{$channel}) {
                    my $msg = Net::Async::Redis::PubSub::Message->new(
                        type => $type,
                        channel => $channel,
                        payload => $payload,
                        redis   => $self,
                        subscription => $sub
                    );
                    $sub->events->emit($msg);
                } else {
                    $log->errorf('Have message for unknown pattern channel [%s]', $channel);
                }
            }
        } elsif($type eq 'unsubscribe') {
            if(my $sub = delete $self->{subscription_channel}{$channel}) {
                $log->tracef('Removed subscription for [%s]', $channel);
                delete $self->{pubsub} unless keys(%{$self->{subscription_channel}}) or keys(%{$self->{subscription_pattern_channel}});
            } else {
                $log->errorf('Have unsubscription for unknown channel [%s]', $channel);
            }
        } elsif($type eq 'punsubscribe') {
            if(my $sub = delete $self->{subscription_pattern_channel}{$channel}) {
                $log->tracef('Removed pattern subscription for [%s]', $channel);
                delete $self->{pubsub} unless keys(%{$self->{subscription_channel}}) or keys(%{$self->{subscription_pattern_channel}});
            } else {
                $log->errorf('Have pattern unsubscription for unknown channel [%s]', $channel);
            }
        } elsif($type eq 'subscribe') {
            $log->errorf('Have subscription for unknown channel [%s]', $channel) unless exists $self->{subscription_channel}{$channel};
        } elsif($type eq 'punsubscribe') {
            $log->errorf('Have subscription for unknown pattern channel [%s]', $channel) unless exists $self->{subscription_pattern_channel}{$channel};
        } else {
            $log->errorf('have unknown pubsub message type %s with channel %s payload %s', $type, $channel, $payload);
        }
		$self->bus->invoke_event(message => $data) if exists $self->{bus};
	} else {
		my $next = shift @{$self->{pending}} or die "No pending handler";
		$next->[1]->done($data);
	}
}

=head2 stream

Represents the L<IO::Async::Stream> instance for the active Redis connection.

=cut

sub stream { shift->{stream} }

=head2 pipeline_depth

Number of requests awaiting responses before we start queuing.

See L<https://redis.io/topics/pipelining> for more details on this concept.

=cut

sub pipeline_depth { shift->{pipeline_depth} }

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
	$self->configure(on_read => sub { 0 });
	$_->[1]->fail('Server connection is no longer active', redis => 'disconnected') for @{$self->{pending}};
	$self->maybe_invoke_event(disconnect => );
}

sub command_label {
	my ($self, @cmd) = @_;
	return join ' ', @cmd if $cmd[0] eq 'KEYS';
	return $cmd[0];
}

sub execute_command {
	my ($self, @cmd) = @_;
    return Future->fail(
        'Currently in pubsub mode, cannot send regular commands until unsubscribed',
        redis =>
            0 + (keys %{$self->{subscription_channel}}),
            0 + (keys %{$self->{subscription_pattern_channel}})
    ) if keys(%{$self->{subscription_channel}}) + keys(%{$self->{subscription_pattern_channel}});
	my $f = $self->loop->new_future->set_label($self->command_label(@cmd));
	push @{$self->{pending}}, [ join(' ', @cmd), $f ];
    return $self->stream->write(
        $self->protocol->encode_from_client(@cmd)
    )->then(sub {
        $f
    });
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
            handler => $self->curry::weak::on_message
        )
    };
}

1;

__END__

=head1 SEE ALSO

Some other Redis implementations on CPAN:

=over 4

=item * L<Mojo::Redis2> - nonblocking, using the L<Mojolicious> framework, actively maintained

=item * L<RedisDB>

=item * L<Cache::Redis>

=back

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2015-2017. Licensed under the same terms as Perl itself.

