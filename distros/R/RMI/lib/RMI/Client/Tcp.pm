package RMI::Client::Tcp;

use strict;
use warnings;
use version;
our $VERSION = qv('0.1');

use base 'RMI::Client';

use IO::Socket;

RMI::Node::_mk_ro_accessors(__PACKAGE__, qw/host port/);

our $DEFAULT_HOST = "127.0.0.1";
our $DEFAULT_PORT = 4409;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(
            host => $DEFAULT_HOST,
            port => $DEFAULT_PORT,
            reader => 1, # replaced below
            writer => 1, # replaced below
            @_
    );
    return unless $self;

    my $socket = IO::Socket::INET->new(
        PeerHost => $self->host,
        PeerPort => $self->port,
        ReuseAddr => 1,
        #ReusePort => 1,
    );
    unless ($socket) {
        my $msg = sprintf(
            "Error connecting to remote host %s on port %s : $!",
            $self->host,
            $self->port
        );
        $self = undef;
        die $msg;
    }

    $self->{reader} = $socket;
    $self->{writer} = $socket;

    return $self;
}

1;

=pod

=head1 NAME

RMI::Client::Tcp - an RMI::Client implementation using TCP/IP sockets

=head1 SYNOPSIS

    $c = RMI::Client::Tcp->new(
        host => 'myserver.com', # defaults to 'localhost'
        port => 1234            # defaults to 4409
    );

    $c->call_use('IO::File');
    $remote_fh = $c->call_class_method('IO::File', 'new', '/my/file');
    print <$remote_fh>;
    
=head1 DESCRIPTION

This subclass of RMI::Client makes a TCP/IP socket connection to an
B<RMI::Server::Tcp>.  See B<RMI::Client> for details on the general client 
API.

See for B<RMI::Server::Tcp> for details on how to start a matching
B<RMI::Server>.

See the general B<RMI> description for an overview of how RMI::Client and
RMI::Servers interact, and examples.   

=head1 METHODS

This class overrides the constructor for a default RMI::Client to make a
socket connection.  That socket is both the reader and writer handle for the
client.

=head1 BUGS AND CAVEATS

See general bugs in B<RMI> for general system limitations of proxied objects.

=head1 SEE ALSO

B<RMI>, B<RMI::Server::Tcp>, B<RMI::Client>, B<RMI::Server>, B<RMI::Node>, B<RMI::ProxyObject>

=cut

