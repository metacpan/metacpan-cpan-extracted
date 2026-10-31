package Net::Async::Kubernetes::PortForwardListener;
# ABSTRACT: Local TCP listeners forwarding to pod ports, like kubectl port-forward
our $VERSION = '0.012';
use strict;
use warnings;
use Carp qw(croak);
use Future;
use Scalar::Util qw(refaddr);

sub new {
    my ($class, %args) = @_;
    croak "kube required" unless $args{kube};
    croak "mappings required" unless ref($args{mappings}) eq 'HASH';
    croak "forward_args required" unless ref($args{forward_args}) eq 'ARRAY';
    $args{host} //= '127.0.0.1';
    $args{_listeners} = {};
    $args{_ports}     = {};
    $args{_conns}     = {};
    return bless \%args, $class;
}


sub start {
    my ($self) = @_;
    my $loop = $self->{kube}->loop;

    my @listening;
    for my $local (sort { $a <=> $b } keys %{$self->{mappings}}) {
        my $remote = $self->{mappings}{$local};
        push @listening, $loop->listen(
            host     => $self->{host},
            service  => "$local",
            socktype => 'stream',
            on_stream => sub {
                my ($stream) = @_;
                $self->_accept($stream, $remote);
            },
        )->on_done(sub {
            my ($listener) = @_;
            $self->{_listeners}{$remote} = $listener;
            $self->{_ports}{$remote}     = $listener->read_handle->sockport;
        });
    }

    return Future->needs_all(@listening)->then(sub {
        return Future->done($self);
    })->else(sub {
        my ($error) = @_;
        $self->stop;
        return Future->fail('port_forward_listen: ' . $error);
    });
}

sub port_for {
    my ($self, $remote) = @_;
    return $self->{_ports}{$remote};
}


sub host { $_[0]->{host} }


sub connection_count { scalar keys %{$_[0]->{_conns}} }


sub stop {
    my ($self) = @_;
    $self->{stopped} = 1;
    for my $remote (keys %{$self->{_listeners}}) {
        my $listener = delete $self->{_listeners}{$remote};
        $listener->close;
        $listener->remove_from_parent;
    }
    $self->_end($_) for values %{$self->{_conns}};
    return;
}


sub _report {
    my ($self, $message) = @_;
    return unless ref($self->{on_error}) eq 'CODE';
    my $ok = eval { $self->{on_error}->($message); 1 };
    warn $@ unless $ok;
    return;
}

# One accepted TCP connection: its own port-forward session to $remote.
sub _accept {
    my ($self, $stream, $remote) = @_;

    my $conn = { stream => $stream, remote => $remote, buffer => '' };
    $self->{_conns}{refaddr $conn} = $conn;

    if ($self->{stopped}) {
        $self->_end($conn);
        return;
    }

    $stream->configure(
        on_read => sub {
            my (undef, $buffref) = @_;
            my $data = $$buffref;
            $$buffref = '';
            $self->_from_tcp($conn, $data) if length $data;
            return 0;
        },
        on_read_eof   => sub { $self->_end($conn) },
        on_read_error => sub { $self->_end($conn, 'local read error: ' . ($_[1] // '')) },
        on_write_error => sub { $self->_end($conn, 'local write error: ' . ($_[1] // '')) },
        on_closed     => sub { $self->_end($conn) },
    );
    $self->{kube}->loop->add($stream);

    my $label = 'port ' . $remote;
    $conn->{future} = $self->{kube}->port_forward(
        @{$self->{forward_args}},
        ports   => [$remote],
        on_open => sub {
            my ($session) = @_;
            # the connection ended while the session request was pending
            if ($conn->{closed}) {
                eval { $session->close(code => 1000); 1 };
                return;
            }
            $conn->{session} = $session;
            my $buffered = delete $conn->{buffer};
            $self->_from_tcp($conn, $buffered) if length $buffered;
        },
        on_data => sub {
            my ($session, $port, $bytes) = @_;
            $conn->{stream}->write($bytes) if $conn->{stream} && !$conn->{closed};
        },
        on_port_error => sub {
            my ($session, $port, $message) = @_;
            $self->_end($conn, "$label: $message");
        },
        on_error => sub {
            my ($error) = @_;
            $self->_end($conn, "$label: $error");
        },
        on_close => sub { $self->_end($conn) },
    )->on_fail(sub {
        my ($error) = @_;
        $self->_end($conn, "$label: $error");
    });
    return;
}

sub _from_tcp {
    my ($self, $conn, $data) = @_;
    return if $conn->{closed};
    unless ($conn->{session}) {
        $conn->{buffer} .= $data;
        return;
    }
    my $ok = eval { $conn->{session}->write_port($conn->{remote}, $data); 1 };
    $self->_end($conn, 'port ' . $conn->{remote} . ': ' . $@) unless $ok;
    return;
}

# Close both sides of a connection once; a $reason is an error to report.
sub _end {
    my ($self, $conn, $reason) = @_;
    return if $conn->{closed}++;
    delete $self->{_conns}{refaddr $conn};
    $self->_report($reason) if defined $reason;

    my $session = delete $conn->{session};
    my $stream  = delete $conn->{stream};
    my $future  = delete $conn->{future};
    delete $conn->{buffer};
    if ($session) {
        eval { $session->close(code => 1000); 1 };
    } elsif ($future && !$future->is_ready) {
        # Cancelled on the next loop iteration, never in place: _end also
        # runs inside the request's own callbacks (a failed connect reports
        # through on_error before the request future fails), and the
        # deferred closure keeps the request alive until those have unwound.
        # Freeing a sequence future from its own callback crashes Future::XS.
        if (my $loop = $self->{kube}->loop) {
            $loop->later(sub { $future->cancel unless $future->is_ready });
        } else {
            $future->cancel;
        }
    }
    eval { $stream->close_when_empty; 1 } if $stream && $stream->loop;
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Kubernetes::PortForwardListener - Local TCP listeners forwarding to pod ports, like kubectl port-forward

=head1 VERSION

version 0.012

=head1 SYNOPSIS

    my $listener = $kube->port_forward_listen('Pod', 'web',
        namespace => 'default',
        ports     => { 0 => 80 },
        on_error  => sub { warn "forward: $_[0]\n" },
    )->get;

    my $port = $listener->port_for(80);
    # ... talk HTTP to 127.0.0.1:$port ...
    $listener->stop;

=head1 DESCRIPTION

The handle L<Net::Async::Kubernetes/port_forward_listen> resolves with. It
owns the local listening sockets and, for every accepted TCP connection, one
port-forward session of its own (see L<Net::Async::Kubernetes/port_forward>)
for the remote port the local port maps to. Bytes read from the connection
are written to the session's data channel and bytes from the pod written back
to the connection. The connection and the session end together.

=head2 new

Built by L<Net::Async::Kubernetes/port_forward_listen>, which validates its
arguments; there is no reason to call this directly.

=head2 port_for

    my $local = $listener->port_for(8080);

The local TCP port that forwards to remote C<$remote>: the one given in
C<ports>, or the one the system picked for a local port of C<0>. C<undef> for
a remote port that is not forwarded.

=head2 host

The local address the listeners are bound to.

=head2 connection_count

The number of forwarded connections currently open.

=head2 stop

    $listener->stop;

Close the listening sockets and every open connection, together with its
port-forward session. Safe to call more than once. The listener cannot be
restarted; open a new one.

=head1 SEE ALSO

L<Net::Async::Kubernetes>, L<Net::Async::Kubernetes::PortForwardSession>,
L<IO::Async::Listener>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-net-async-kubernetes/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
