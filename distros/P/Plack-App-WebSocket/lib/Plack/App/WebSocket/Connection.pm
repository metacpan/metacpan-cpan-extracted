package Plack::App::WebSocket::Connection;
use strict;
use warnings;
use Carp;
use Scalar::Util qw(weaken);
use Devel::GlobalDestruction ();
use AnyEvent;

our $VERSION = "0.05";

sub new {
    my ($class, $conn, $responder) = @_;
    my $self = bless {
        connection => $conn,
        responder => $responder,
        handlers => {
            message => [],
            finish  => [],
        },
    }, $class;
    $self->_setup_internal_event_handlers();
    return $self;
}

sub _setup_internal_event_handlers {
    my ($self) = @_;
    weaken $self;
    $self->{connection}->on(each_message => sub {
        return if !defined($self);
        my $strong_self = $self; ## make sure $self is alive during callback execution
        $_->($self, $_[1]->body) foreach @{$self->{handlers}{message}};
    });
    $self->{connection}->on(finish => sub {
        return if !defined($self);
        my $strong_self = $self; ## make sure $self is alive during callback execution
        $_->($self) foreach @{$self->{handlers}{finish}};
    });
}

sub _clear_event_handlers {
    my ($self) = @_;
    foreach my $handler_list (values %{$self->{handlers}}) {
        @$handler_list = ();
    }
}

sub on {
    my ($self, %handlers) = @_;
    foreach my $event (keys %handlers) {
        my $handler = $handlers{$event};
        croak "handler for event $event must be a code-ref" if ref($handler) ne "CODE";
        $event = "finish" if $event eq "close";
        my $handler_list = $self->{handlers}{$event};
        croak "Unknown event: $event" if not defined $handler_list;
        push(@$handler_list, $handler);
    }
}

sub send {
    my ($self, $message) = @_;
    $self->{connection}->send($message);
}

sub close {
    my ($self) = @_;
    $self->{connection}->close;
}

our $WAIT_FOR_FLUSHING_SEC = 5;

sub DESTROY {
    my ($self) = @_;
    return if Devel::GlobalDestruction::in_global_destruction;
    $self->_clear_event_handlers();
    my $connection = $self->{connection};
    $connection->close();  ## explicit close because $responder may keep the socket.
    my $responder = $self->{responder};
    my $w; $w = AnyEvent->timer(after => $WAIT_FOR_FLUSHING_SEC, cb => sub {
        $responder->([200, ["Content-Type", "text/plain"], ["WebSocket finished"]]);
        undef $w;
        undef $responder;

        ## Prolong $connection's life as long as $responder. This is
        ## necessary to make sure $connection actively shuts down the
        ## socket. If $connection is destroyed immediately and the
        ## kernel's write buffer is full, $connection may fail to shut
        ## down the socket (because $connection delays the active
        ## shutdown after sending all the buffered data). If that
        ## happens, the socket stays open, which is bad.
        undef $connection;
    });
}

1;

__END__

=pod

=head1 NAME

Plack::App::WebSocket::Connection - WebSocket connection for Plack::App::WebSocket

=head1 SYNOPSIS

    my $app = Plack::App::WebSocket->new(on_establish => sub {
        my $connection = shift;
        $connection->on(message => sub {
            my ($connection, $message) = @_;
            warn "Received: $message\n";
            if($message eq "quit") {
                $connection->close();
            }
        });
        $connection->on(finish => sub {
            warn "Closed\n";
            undef $connection;
        });
        $connection->send("Message to the client");
    });

=head1 DESCRIPTION

L<Plack::App::WebSocket::Connection> is an object representing a
WebSocket connection to a client. It is created by
L<Plack::App::WebSocket> internally and given to you in
C<on_establish> callback function.

=head1 OBJECT METHODS

=head2 $connection->on($event => $handler)

Register a callback function to a particular event.
You can register multiple callbacks to the same event.

C<$event> is a string and C<$handler> is a subroutine reference.

Possible value for C<$event> is:

=over

=item C<"message">

    $handler->($connection, $message)

C<$handler> is called for each message received via the C<$connection>.
Argument C<$connection> is the L<Plack::App::WebSocket::Connection> object,
and C<$message> is a non-decoded byte string of the received message.

=item C<"finish"> (alias: C<"close">)

    $handler->($connection)

C<$handler> is called when the C<$connection> is closed.
Argument C<$connection> is the L<Plack::App::WebSocket::Connection> object.

=back

=head2 $connection->send($message)

Send a message via C<$connection>.

C<$message> should be a UTF-8 encoded string.

=head2 $connection->close()

Close the WebSocket C<$connection>.

=head1 AUTHOR

Toshio Ito, C<< <toshioito at cpan.org> >>


=cut
