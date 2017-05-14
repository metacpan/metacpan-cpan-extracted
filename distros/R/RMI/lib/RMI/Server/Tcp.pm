package RMI::Server::Tcp;
use base 'RMI::Server';

use strict;
use warnings;
use version;
our $VERSION = qv('0.1');

use RMI;
use IO::Socket;
use IO::Select;
use Fcntl;

RMI::Node::_mk_ro_accessors(__PACKAGE__, qw/host port listen_socket all_select sockets_select listen_queue_size/);

our $DEFAULT_PORT = 4409;

sub new {
    my $class = shift;

    my $self = bless { port => $DEFAULT_PORT, @_ }, $class;
    return unless $self;

    unless ($self->listen_socket) {
        my $listen = IO::Socket::INET->new(
            LocalHost => $self->host,
            LocalPort => $self->port,
            ReuseAddr => 1,
            Listen    => $self->listen_queue_size,
        );
        unless ($listen) {
            die "Couldn't create socket: $!";
        }
        $self->{listen_socket} = $listen;
        $self->{all_select} = IO::Select->new($listen);
        $self->{sockets_select} = IO::Select->new();
        $self->{data_ready} = [];
    }

    return $self;
}

# Override in the base class to delegate to whichever socket returns a value next.
# Note, that this only receives queries, since the delegate will receive all responses
# to our own counter queries.

sub receive_request_and_send_response {
    my ($self,$timeout) = @_;
    
    # the list of all sockets w/ data ready
    my $data_ready = $self->{data_ready};
    
    # ck for new connections and also new sockets with data
    my $select = $self->all_select;
    until (@$data_ready) {
        my @new_readable = $select->can_read($timeout);
        unless (@new_readable) {
            return;
        }
        my @new_data;
        for (my $i = 0; $i < @new_readable; $i++) {
            if ($new_readable[$i] eq $self->listen_socket) {
                $self->_accept_connection();;
            }
            else {
                push @new_data, $new_readable[$i]
            }
        }
        push @$data_ready, @new_data;
    }
    
    # process the first socket with data
    # delegate to the right "server" object, which manages just this particular client
    my $ready = shift @$data_ready;
    my $delegate_server = $self->{_server_for_socket}{$ready};
    my $retval = $delegate_server->receive_request_and_send_response;    
    return $retval;
}

# Add the given socket to the list of connected clients.
# if socket is undef, it blocks waiting on an incoming connection 
sub _accept_connection {
    my $self = shift;
    my $socket = shift;

    unless ($socket) {
        my $listen = $self->listen_socket;
        $socket = $listen->accept();
        unless ($socket) {
            die "accept() failed: $!";
        }
    }

    my $server = RMI::Server->new(
        reader => $socket,
        writer => $socket,
        peer_pid => "$socket",
    );
    unless ($server) {
        die "failed to create RMI::Server for accepted socket";
    }

    $self->{_server_for_socket}{$socket} = $server;
    
    $self->sockets_select->add($socket);
    $self->all_select->add($socket);
    return $socket;
}

sub _close_connection {
    # This is no longer called, and somehow the select sockets get things removed?
    my $self = shift;
    my $socket = shift;

    unless ($self->sockets_select->exists($socket)) {
        warn ("Passed-in socket $socket is not on the list of connected clients");
    }
    unless ($self->all_select->exists($socket)) {
        warn ("Passed-in socket $socket is not on the list of all clients");
    }
    print "removed $socket\n";

    $self->sockets_select->remove($socket);
    $self->all_select->remove($socket);
    $socket->close();
    return 1;
}

1;


=pod

=head1 NAME

RMI::Server::Tcp - service RMI::Client::Tcp requests

=head1 SYNOPSIS

    $s = RMI::Server::Tcp->new(
        port => 1234            # defaults to 4409
    );
    $s->run;
    
=head1 DESCRIPTION

This subclass of RMI::Server makes a TCP/IP listening socket, and accepts
multiple non-blocking IO connections.

=head1 METHODS

This class overrides the constructor for a default RMI::Server to make a
listening socket.  Individual accepted connections get their own private
subordinate RMI::Server of this class.

=head1 BUGS AND CAVEATS

See general bugs in B<RMI> for general system limitations of proxied objects.

=head1 SEE ALSO

B<RMI>, B<RMI::Client::Tcp>, B<RMI::Client>, B<RMI::Server>, B<RMI::Node>, B<RMI::ProxyObject>

=cut

