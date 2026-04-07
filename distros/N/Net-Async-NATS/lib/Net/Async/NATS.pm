package Net::Async::NATS;
# ABSTRACT: Async NATS client for IO::Async
our $VERSION = '0.003';
use strict;
use warnings;
use parent 'IO::Async::Notifier';

use Carp qw(croak);
use Future;
use Future::AsyncAwait;
use IO::Async::Stream;
use JSON::MaybeXS qw(encode_json decode_json);
use Scalar::Util qw(weaken);

use Net::Async::NATS::Subscription;


sub configure {
    my ($self, %params) = @_;

    for my $key (qw(host port name user pass auth_token
                     verbose pedantic reconnect max_reconnect_attempts
                     reconnect_wait on_disconnect on_error on_connect)) {
        $self->{$key} = delete $params{$key} if exists $params{$key};
    }

    # Defaults
    $self->{host}     //= 'localhost';
    $self->{port}     //= 4222;
    $self->{name}     //= 'net-async-nats-perl';
    $self->{verbose}  //= 0;
    $self->{pedantic} //= 0;
    $self->{reconnect} //= 1;
    $self->{max_reconnect_attempts} //= 10;
    $self->{reconnect_wait} //= 2;

    # Internal state
    $self->{_sid_counter}   //= 0;
    $self->{_subscriptions} //= {};
    $self->{_pending}       //= [];
    $self->{_connected}     //= 0;
    $self->{_server_info}   //= {};
    $self->{_ping_future}   //= undef;
    $self->{_connect_future} //= undef;
    $self->{_inbox_prefix}  //= '_INBOX.' . _random_id();

    $self->SUPER::configure(%params);
}


sub host     { $_[0]->{host} }
sub port     { $_[0]->{port} }
sub name     { $_[0]->{name} }
sub verbose  { $_[0]->{verbose} }
sub pedantic { $_[0]->{pedantic} }


sub server_info  { $_[0]->{_server_info} }
sub is_connected { $_[0]->{_connected} }


async sub connect {
    my ($self) = @_;

    croak "Already connected" if $self->{_connected};

    # Clean up any stale future from a previous failed connect
    if (my $f = delete $self->{_connect_future}) {
        $f->cancel unless $f->is_ready;
    }
    if (my $f = delete $self->{_tcp_connect_future}) {
        $f->cancel unless $f->is_ready;
    }

    $self->{_connect_future} = $self->loop->new_future;

    my $stream = IO::Async::Stream->new(
        handle => undef,
        on_read => sub { $self->_on_read(@_) },
        on_read_eof => sub { $self->_on_disconnect('read_eof') },
        on_write_eof => sub { $self->_on_disconnect('write_eof') },
        on_read_error => sub { $self->_on_error("Read error: $_[1]") },
        on_write_error => sub { $self->_on_error("Write error: $_[1]") },
    );
    $self->{_stream} = $stream;
    $self->add_child($stream);

    # Retain the TCP connect future — if GC'd before resolution, the
    # stream never gets its handle and on_read never fires.
    $self->{_tcp_connect_future} = $stream->connect(
        host    => $self->{host},
        service => $self->{port},
    )->on_fail(sub {
        my $err = shift;
        $self->{_connect_future}->fail("Connection failed: $err")
            unless $self->{_connect_future}->is_ready;
    });

    return await $self->{_connect_future};
}


async sub publish {
    my ($self, $subject, $payload, %opts) = @_;

    croak "Not connected" unless $self->{_connected};
    croak "Subject required" unless defined $subject && length $subject;

    $payload //= '';
    my $bytes = length($payload);
    my $reply = $opts{reply_to};

    my $cmd = defined $reply
        ? "PUB $subject $reply $bytes\r\n$payload\r\n"
        : "PUB $subject $bytes\r\n$payload\r\n";

    $self->_write($cmd);
    return;
}


async sub subscribe {
    my ($self, $subject, $callback, %opts) = @_;

    croak "Not connected" unless $self->{_connected};
    croak "Subject required" unless defined $subject && length $subject;
    croak "Callback required" unless ref $callback eq 'CODE';

    my $sid   = ++$self->{_sid_counter};
    my $queue = $opts{queue};

    my $sub = Net::Async::NATS::Subscription->new(
        sid      => $sid,
        subject  => $subject,
        queue    => $queue,
        callback => $callback,
    );
    $self->{_subscriptions}{$sid} = $sub;

    my $cmd = defined $queue
        ? "SUB $subject $queue $sid\r\n"
        : "SUB $subject $sid\r\n";

    $self->_write($cmd);
    return $sub;
}


async sub unsubscribe {
    my ($self, $sub, %opts) = @_;

    croak "Not connected" unless $self->{_connected};

    my $sid = ref $sub ? $sub->sid : $sub;
    my $max = $opts{max_msgs};

    my $cmd = defined $max
        ? "UNSUB $sid $max\r\n"
        : "UNSUB $sid\r\n";

    $self->_write($cmd);
    delete $self->{_subscriptions}{$sid} unless defined $max;
    return;
}


async sub request {
    my ($self, $subject, $payload, %opts) = @_;

    croak "Not connected" unless $self->{_connected};

    my $timeout = $opts{timeout} // 30;
    my $inbox   = $self->{_inbox_prefix} . '.' . _random_id();
    my $f       = $self->loop->new_future;

    my $sub = await $self->subscribe($inbox, sub {
        my ($subj, $data, $reply) = @_;
        $f->done($data, $subj) unless $f->is_ready;
    });

    # Auto-unsubscribe after 1 message
    await $self->unsubscribe($sub, max_msgs => 1);

    # Publish with reply-to
    await $self->publish($subject, $payload, reply_to => $inbox);

    # Apply timeout
    my $timer = $self->loop->delay_future(after => $timeout);
    my $result = await Future->wait_any($f, $timer->then_fail('Request timed out'));

    return $result;
}


async sub ping {
    my ($self) = @_;
    croak "Not connected" unless $self->{_connected};

    $self->{_ping_future} = $self->loop->new_future;
    $self->_write("PING\r\n");
    return await $self->{_ping_future};
}


async sub disconnect {
    my ($self) = @_;
    return unless $self->{_connected};

    $self->{_connected}  = 0;
    $self->{reconnect}   = 0;  # suppress auto-reconnect
    $self->{_subscriptions} = {};

    if (my $stream = $self->{_stream}) {
        $stream->close_when_empty;
    }
    return;
}

# ── Wire protocol parsing ────────────────────────────────

sub _on_read {
    my ($self, $stream, $buffref, $eof) = @_;

    while ($$buffref =~ s/\A([^\r\n]*)\r\n//) {
        my $line = $1;

        # MSG <subject> <sid> [reply-to] <#bytes>
        if ($line =~ /\AMSG\s+(\S+)\s+(\S+)\s+(?:(\S+)\s+)?(\d+)\z/i) {
            my ($subject, $sid, $reply_to, $bytes) = ($1, $2, $3, $4);

            # Need to read payload + trailing CRLF
            if (length($$buffref) < $bytes + 2) {
                # Put line back, wait for more data
                $$buffref = "MSG $subject $sid "
                    . (defined $reply_to ? "$reply_to " : '')
                    . "$bytes\r\n$$buffref";
                return 0;
            }

            my $payload = substr($$buffref, 0, $bytes, '');
            $$buffref =~ s/\A\r\n//;  # consume trailing CRLF

            $self->_dispatch_msg($subject, $sid, $reply_to, $payload);
            next;
        }

        # HMSG <subject> <sid> [reply-to] <#header_bytes> <#total_bytes>
        if ($line =~ /\AHMSG\s+(\S+)\s+(\S+)\s+(?:(\S+)\s+)?(\d+)\s+(\d+)\z/i) {
            my ($subject, $sid, $reply_to, $hdr_bytes, $total_bytes) = ($1, $2, $3, $4, $5);

            if (length($$buffref) < $total_bytes + 2) {
                $$buffref = "HMSG $subject $sid "
                    . (defined $reply_to ? "$reply_to " : '')
                    . "$hdr_bytes $total_bytes\r\n$$buffref";
                return 0;
            }

            my $raw = substr($$buffref, 0, $total_bytes, '');
            $$buffref =~ s/\A\r\n//;

            my $payload_bytes = $total_bytes - $hdr_bytes;
            my $payload = $payload_bytes > 0
                ? substr($raw, $hdr_bytes)
                : '';

            # For now, ignore headers — deliver payload only
            $self->_dispatch_msg($subject, $sid, $reply_to, $payload);
            next;
        }

        # INFO {...}
        if ($line =~ /\AINFO\s+(\{.*\})\s*\z/i) {
            my $info = eval { decode_json($1) } // {};
            $self->{_server_info} = $info;
            $self->_handle_info($info);
            next;
        }

        # PING
        if ($line =~ /\APING\z/i) {
            $self->_write("PONG\r\n");
            next;
        }

        # PONG
        if ($line =~ /\APONG\z/i) {
            if (my $f = delete $self->{_ping_future}) {
                $f->done if !$f->is_ready;
            }
            next;
        }

        # +OK
        next if $line =~ /\A\+OK\z/i;

        # -ERR
        if ($line =~ /\A-ERR\s+'?(.+?)'?\z/i) {
            $self->_on_error($1);
            next;
        }
    }

    return 0;
}

sub _handle_info {
    my ($self, $info) = @_;

    # If we haven't sent CONNECT yet, do it now
    return if $self->{_connected};

    my %connect = (
        verbose     => $self->{verbose} ? \1 : \0,
        pedantic    => $self->{pedantic} ? \1 : \0,
        tls_required => \0,
        lang        => 'perl',
        version     => ($Net::Async::NATS::VERSION // '0.001'),
        name        => $self->{name},
        protocol    => 1,
        echo        => \1,
        headers     => \1,
        no_responders => \1,
    );

    if (defined $self->{auth_token}) {
        $connect{auth_token} = $self->{auth_token};
    }
    if (defined $self->{user}) {
        $connect{user} = $self->{user};
        $connect{pass} = $self->{pass} // '';
    }

    my $json = encode_json(\%connect);
    $self->_write("CONNECT $json\r\n");

    # Send initial PING to verify connection
    $self->_write("PING\r\n");

    $self->{_connected} = 1;
    delete $self->{_tcp_connect_future};  # no longer needed

    if (my $f = delete $self->{_connect_future}) {
        $f->done($info) unless $f->is_ready;
    }

    if (my $cb = $self->{on_connect}) {
        $cb->($self, $info);
    }
}

sub _dispatch_msg {
    my ($self, $subject, $sid, $reply_to, $payload) = @_;

    my $sub = $self->{_subscriptions}{$sid};
    return unless $sub;

    $sub->callback->($subject, $payload, $reply_to);

    if (defined $sub->max_msgs) {
        $sub->{_received}++;
        if ($sub->{_received} >= $sub->max_msgs) {
            delete $self->{_subscriptions}{$sid};
        }
    }
}

sub _write {
    my ($self, $data) = @_;
    if (my $stream = $self->{_stream}) {
        $stream->write($data);
    }
}

sub _on_disconnect {
    my ($self, $reason) = @_;
    $self->{_connected} = 0;

    # Abort any pending connect Future so its async sub unwinds cleanly
    if (my $f = delete $self->{_connect_future}) {
        $f->fail("disconnected: $reason") unless $f->is_ready;
    }

    if (my $cb = $self->{on_disconnect}) {
        $cb->($self, $reason);
    }

    if ($self->{reconnect}) {
        $self->_reconnect;
    }
}

sub _on_error {
    my ($self, $error) = @_;
    if (my $cb = $self->{on_error}) {
        $cb->($self, $error);
    }
}

sub _reconnect {
    my ($self) = @_;

    # Guard against overlapping reconnect chains
    return if $self->{_reconnect_future};

    $self->{_reconnect_attempts} = 0;
    $self->_reconnect_attempt;
}

sub _reconnect_attempt {
    my ($self) = @_;

    return if $self->{_connected};
    if (++$self->{_reconnect_attempts} > $self->{max_reconnect_attempts}) {
        delete $self->{_reconnect_future};
        $self->_on_error("reconnect failed after $self->{max_reconnect_attempts} attempts");
        return;
    }

    weaken(my $weak_self = $self);

    # Remove old stream before waiting
    if (my $old = delete $self->{_stream}) {
        $self->remove_child($old) if $old->parent;
    }

    # Save subscriptions for replay (once, on first attempt)
    $self->{_saved_subs} //= { %{ $self->{_subscriptions} } };
    $self->{_subscriptions} = {};

    # Hold the full reconnect-attempt future on the object so nothing is GC'd
    $self->{_reconnect_future} = $self->loop
        ->delay_future(after => $self->{reconnect_wait})
        ->then(sub {
            my $self = $weak_self or return Future->done;
            return Future->done if $self->{_connected};
            return $self->connect;
        })
        ->on_done(sub {
            my $self = $weak_self or return;
            # Replay subscriptions on the new connection
            my $saved = delete $self->{_saved_subs} || {};
            for my $sub (values %$saved) {
                my $cmd = defined $sub->queue
                    ? "SUB " . $sub->subject . " " . $sub->queue . " " . $sub->sid . "\r\n"
                    : "SUB " . $sub->subject . " " . $sub->sid . "\r\n";
                $self->_write($cmd);
                $self->{_subscriptions}{$sub->sid} = $sub;
            }
            delete $self->{_reconnect_future};
        })
        ->on_fail(sub {
            my $self = $weak_self or return;
            delete $self->{_reconnect_future};
            $self->_reconnect_attempt;  # try again
        });
}

sub _random_id {
    my $bytes = '';
    if (open my $fh, '<:raw', '/dev/urandom') {
        read $fh, $bytes, 12;
        close $fh;
    } else {
        $bytes = pack('N3', rand(2**32), rand(2**32), rand(2**32));
    }
    return unpack('H*', $bytes);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::NATS - Async NATS client for IO::Async

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use IO::Async::Loop;
    use Net::Async::NATS;

    my $loop = IO::Async::Loop->new;
    my $nats = Net::Async::NATS->new(
        host => 'localhost',
        port => 4222,
    );
    $loop->add($nats);

    await $nats->connect;

    # Subscribe
    my $sub = await $nats->subscribe('greet.*', sub {
        my ($subject, $payload, $reply_to) = @_;
        print "Got: $payload on $subject\n";
    });

    # Publish
    await $nats->publish('greet.world', 'Hello!');

    # Request/Reply
    my ($payload) = await $nats->request('service.echo', 'ping', timeout => 5);

    # Unsubscribe
    await $nats->unsubscribe($sub);

    # Disconnect
    await $nats->disconnect;

=head1 DESCRIPTION

L<Net::Async::NATS> is an asynchronous client for the L<NATS|https://nats.io>
messaging system, built on L<IO::Async>. It implements the full NATS client
wire protocol over TCP using L<IO::Async::Stream>.

Features:

=over

=item * Publish/Subscribe messaging

=item * Request/Reply with auto-generated inbox subjects

=item * Wildcard subscriptions (C<*> and C<E<gt>>)

=item * Queue group subscriptions

=item * Automatic PING/PONG keepalive handling

=item * Reconnect with subscription replay

=item * Server INFO processing and cluster URL discovery

=back

=head2 host

NATS server hostname. Default: C<localhost>.

=head2 port

NATS server port. Default: C<4222>.

=head2 name

Client name sent in CONNECT. Default: C<net-async-nats-perl>.

=head2 verbose

If true, server sends C<+OK> for each protocol message. Default: false.

=head2 pedantic

If true, server performs strict protocol checking. Default: false.

=head2 reconnect

If true, automatically reconnect on disconnect. Default: true.

=head2 max_reconnect_attempts

Maximum number of reconnect attempts. Default: C<10>.

=head2 reconnect_wait

Seconds between reconnect attempts. Default: C<2>.

=head2 user

Optional username for authentication.

=head2 pass

Optional password for authentication. Used together with L</user>.

=head2 auth_token

Optional authentication token. Alternative to username/password auth.

=head2 on_connect

Optional callback invoked when the connection is established and the CONNECT
handshake completes. Called as C<$cb->($nats, $info)> where C<$info> is the
server INFO hashref.

=head2 on_disconnect

Optional callback invoked when the connection is lost. Called as
C<$cb->($nats, $reason)> where C<$reason> is a short string such as
C<read_eof> or C<write_eof>.

=head2 on_error

Optional callback invoked when the server sends a C<-ERR> message. Called as
C<$cb->($nats, $error_message)>.

=head2 server_info

    my $info = $nats->server_info;

Returns the server INFO hashref received during the CONNECT handshake. Keys
include C<server_id>, C<version>, C<max_payload>, etc. Returns an empty
hashref before connecting.

=head2 is_connected

    if ($nats->is_connected) { ... }

Returns true if the client is currently connected to the NATS server.

=head2 connect

    await $nats->connect;

Connect to the NATS server. Returns a L<Future> that resolves when the
connection is established and the CONNECT handshake is complete.

=head2 publish

    await $nats->publish($subject, $payload);
    await $nats->publish($subject, $payload, reply_to => $reply);

Publish a message to the given subject. Payload can be a string or undef
(empty message). Optional C<reply_to> sets the reply subject.

=head2 subscribe

    my $sub = await $nats->subscribe($subject, sub {
        my ($subject, $payload, $reply_to) = @_;
    });

    # With queue group
    my $sub = await $nats->subscribe($subject, $callback, queue => 'workers');

Subscribe to a subject. The callback receives the matched subject, payload,
and optional reply-to subject. Returns a L<Net::Async::NATS::Subscription>
object.

Wildcards: C<*> matches a single token, C<E<gt>> matches one or more tokens
at the tail of the subject.

=head2 unsubscribe

    await $nats->unsubscribe($sub);
    await $nats->unsubscribe($sub, max_msgs => 5);

Unsubscribe from a subscription. With C<max_msgs>, auto-unsubscribe after
receiving that many additional messages.

=head2 request

    my ($payload, $subject) = await $nats->request($subject, $data,
        timeout => 5,
    );

Send a request and wait for a single reply. Uses an auto-generated inbox
subject. Returns the reply payload and subject. Times out after C<timeout>
seconds (default: 30).

=head2 ping

    await $nats->ping;

Send a PING and wait for the server's PONG response.

=head2 disconnect

    await $nats->disconnect;

Gracefully disconnect from the NATS server.

=head1 SEE ALSO

=over

=item * L<https://nats.io> - NATS messaging system

=item * L<https://docs.nats.io/reference/reference-protocols/nats-protocol> - NATS wire protocol

=item * L<IO::Async> - Async framework

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-nats/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
