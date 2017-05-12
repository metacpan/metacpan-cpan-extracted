package Net::Proxy;
$Net::Proxy::VERSION = '0.13';
use strict;
use warnings;
use Carp;
use Scalar::Util qw( refaddr reftype );
use IO::Select;
use POSIX 'strftime';

# interal socket information table
my %SOCK_INFO;
my %LISTENER;
my %CLOSING;
my $READERS;
my $WRITERS;
my %PROXY;
my %STATS;

# Net::Proxy attributes
my %CONNECTOR = (
    in  => {},
    out => {},
);
my $VERBOSITY = 0; # be silent by default
my $BUFFSIZE  = 16384;

#
# some logging-related methods
#
sub set_verbosity { $VERBOSITY = $_[1]; }
{
    my $i;
    for my $meth (qw( error notice info debug )) {
        no strict 'refs';
        my $level = $i++;
        *$meth = sub {
            return if $VERBOSITY < $level;
            print STDERR strftime "%Y-%m-%d %H:%M:%S $_[1]\n", localtime;
        };
    }
}

#
# constructor
#
sub new {
    my ( $class, $args ) = @_;
    my $self = bless \do { my $anon }, $class;

    croak "Argument to new() must be a HASHREF" if ref $args ne 'HASH';

    for my $conn (qw( in out )) {

        # check arguments
        croak "'$conn' connector required" if !exists $args->{$conn};

        croak "'$conn' connector must be a HASHREF"
            if ref $args->{$conn} ne 'HASH';

        croak "'type' key required for '$conn' connector"
            if !exists $args->{$conn}{type};

        croak "'hook' key is not a CODE reference for '$conn' connector"
            if $args->{$conn}{hook}
            && reftype( $args->{$conn}{hook} ) ne 'CODE';
 
        # load the class
        my $class = 'Net::Proxy::Connector::' . $args->{$conn}{type};
        eval "require $class";
        croak "Couldn't load $class for '$conn' connector: $@" if $@;

        # create and store the Connector object
        $args->{$conn}{_proxy_} = $self;
        $CONNECTOR{$conn}{ refaddr $self} = $class->new( $args->{$conn} );
        $CONNECTOR{$conn}{ refaddr $self}->set_proxy($self);
    }

    return $self;
}

sub register { $PROXY{ refaddr $_[0] } = $_[0]; }
sub unregister { delete $PROXY{ refaddr $_[0] }; }

sub get_max_buffer_size { return $BUFFSIZE; }
sub set_max_buffer_size { $BUFFSIZE = $_[1]; }

#
# The Net::Proxy attributes
#
sub in_connector  { return $CONNECTOR{in}{ refaddr $_[0] }; }
sub out_connector { return $CONNECTOR{out}{ refaddr $_[0] }; }

#
# create the socket setter/getter methods
# these are actually Net::Proxy clas methods
#
BEGIN {
    my $n = 0;
    my $buffer_id;
    for my $attr (qw( peer connector state nick buffer callback )) {
        no strict 'refs';
        my $i = $n;
        *{"get_$attr"} = sub { $SOCK_INFO{ refaddr $_[1] }[$i]; };
        *{"set_$attr"} = sub { $SOCK_INFO{ refaddr $_[1] }[$i] = $_[2]; };
        $buffer_id = $n if $attr eq 'buffer';
        $n++;
    }
    # special shortcut
    sub add_to_buffer { $SOCK_INFO{ refaddr $_[1] }[$buffer_id] .= $_[2] if(!exists($CLOSING{$_[1]})); }
}

#
# create statistical methods
#
for my $info (qw( opened closed )) {
    no strict 'refs';
    *{"stat_inc_$info"} = sub {
        $STATS{ refaddr $_[0]}{$info}++;
        $STATS{total}{$info}++;
    };
    *{"stat_$info"}       = sub { $STATS{ refaddr $_[0]}{$info} || 0; };
    *{"stat_total_$info"} = sub { $STATS{total}{$info} || 0; };
}

#
# socket-related methods
#
sub add_listeners {
    my ( $class, @socks ) = @_;
    for my $sock (@socks) {
        Net::Proxy->notice( 'Add ' . Net::Proxy->get_nick($sock) );
        $LISTENER{ refaddr $sock} = $sock;
    }
    return;
}

sub close_sockets {
    my ( $class, @socks ) = @_;

  SOCKET:
    for my $sock (@socks) {
        my $conn = Net::Proxy->get_connector($sock);
        next SOCKET if(!defined($conn));

        if( my $data = Net::Proxy->get_buffer( $sock ) ) {
            ## Net::Proxy->debug( length($data) . ' bytes left to write on ' . Net::Proxy->get_nick( $sock ) );
            $CLOSING{ refaddr $sock} = $sock;
            next SOCKET;
        }

        Net::Proxy->notice( 'Closing ' . Net::Proxy->get_nick( $sock ) );

        # clean up connector
        $conn->close($sock) if $conn->can('close');

        # count connections to the proxy "in connectors" only
        my $proxy = $conn->get_proxy();
        if ( refaddr $conn == refaddr $proxy->in_connector()
            && !_is_listener($sock) )
        {
            $proxy->stat_inc_closed();
        }

        # clean up internal structures
        delete $SOCK_INFO{ refaddr $sock};
        delete $LISTENER{ refaddr $sock};
        delete $CLOSING{ refaddr $sock};

        # clean up sockets
        $READERS->remove($sock);
        $WRITERS->remove($sock);
        $sock->close();
    }

    return;
}

#
# select() stuff
#
sub watch_reader_sockets {
    my ( $class, @socks ) = @_;
    $READERS->add(@socks);
    return;
}

sub watch_writer_sockets {
    my ( $class, @socks ) = @_;
    $WRITERS->add(@socks);
    return;
}

sub remove_writer_sockets {
    my ( $class, @socks ) = @_;
    $WRITERS->remove(@socks);
    return;
}

#
# destructor
#
sub DESTROY {
    my ($self) = @_;
    delete $CONNECTOR{in}{ refaddr $self};
    delete $CONNECTOR{out}{ refaddr $self};
}

#
# the mainloop itself
#
sub mainloop {
    my ( $class, $max_connections ) = @_;
    $max_connections ||= 0;

    # initialise the loop
    $READERS = IO::Select->new();
    $WRITERS = IO::Select->new();

    # initialise all proxies
    for my $proxy ( values %PROXY ) {
        my $in    = $proxy->in_connector();
        my @socks = $in->listen();
        Net::Proxy->add_listeners(@socks);
        Net::Proxy->watch_reader_sockets(@socks);
        Net::Proxy->set_connector( $_, $in ) for @socks;
    }

    my $continue = 1;
    for my $signal (qw( INT HUP )) {
        $SIG{$signal} = sub {
            Net::Proxy->notice("Caught $signal signal");
            $continue = 0;
        };
    }

    # loop indefinitely
    while ( $continue and my @ready = IO::Select->select( $READERS, $WRITERS ) ) {

        ## Net::Proxy->debug( 0+@{$ready[0]} . " sockets ready for reading" );
        ## Net::Proxy->debug( join "\n  ", "Readers:", map { Net::Proxy->get_nick($_) } $READERS->handles() );
        ## Net::Proxy->debug( 0+@{$ready[1]} . " sockets ready for writing" );
        ## Net::Proxy->debug( join "\n  ", "Writers:", map { Net::Proxy->get_nick($_) } $WRITERS->handles() );

        # first read
    READER:
        for my $sock (@{$ready[0]}) {
            if ( _is_listener($sock) ) {

                # accept the new connection and connect to the destination
                Net::Proxy->get_connector($sock)->new_connection_on($sock);
            }
            else {

                # have we read too much?
                my $peer = Net::Proxy->get_peer($sock);
                next READER
                    if !$peer
                    || ($BUFFSIZE && length( Net::Proxy->get_buffer($peer) ) >= $BUFFSIZE);

                # read the data
                if ( my $conn = Net::Proxy->get_connector($sock) ) {
                    my $data = $conn->read_from($sock);
                    next READER if !defined $data;

                    if ($peer) {

                        # run the hook on incoming data
                        my $callback = Net::Proxy->get_callback( $sock );
                        $callback->( \$data, $sock, $conn )
                            if $callback && defined $data;

                        Net::Proxy->add_to_buffer( $peer, $data );
                        Net::Proxy->watch_writer_sockets($peer);

                        ## Net::Proxy->debug( "Will write " . length( Net::Proxy->get_buffer($peer)). " bytes to " .  Net::Proxy->get_nick( $peer ));
                    }
                }
            }
        }

        # then write
        for my $sock (@{$ready[1]}) {
            my $conn = Net::Proxy->get_connector($sock);
            next if(!defined($conn)); # may happen if read_from() closed socket
            $conn->write_to($sock);
        }

    }
    continue {
        if( %CLOSING ) {
            Net::Proxy->close_sockets( values %CLOSING );
        }
        if( $max_connections ) {

            # stop after that many connections
            last if Net::Proxy->stat_total_closed() == $max_connections;

            # prevent new connections
            if ( %LISTENER
                && Net::Proxy->stat_total_opened() == $max_connections )
            {
                Net::Proxy->close_sockets( values %LISTENER );
            }
        }
    }

    # close all remaining sockets
    Net::Proxy->close_sockets( $READERS->handles(), $WRITERS->handles() );
}

#
# helper private FUNCTIONS
#
sub _is_listener { return exists $LISTENER{ refaddr $_[0] }; }

1;

__END__

=encoding utf-8

=head1 NAME

Net::Proxy - Framework for proxying network connections in many ways

=head1 SYNOPSIS

    use Net::Proxy;

    # proxy connections from localhost:6789 to remotehost:9876
    # using standard TCP connections
    my $proxy = Net::Proxy->new(
        {   in  => { type => 'tcp', port => '6789' },
            out => { type => 'tcp', host => 'remotehost', port => '9876' },
        }
    );

    # register the proxy object
    $proxy->register();

    # and you can setup multiple proxies

    # and now proxy connections indefinitely
    Net::Proxy->mainloop();

=head1 DESCRIPTION

A Net::Proxy object represents a proxy that accepts connections
and then relays the data transfered between the source and the destination.

The goal of this module is to abstract the different methods used
to connect from the proxy to the destination.

A proxy is a program that transfer data across a network boundary
between a client and a server. Net::Proxy introduces the concept of
"connectors" (implemented as L<Net::Proxy::Connector> subclasses),
which abstract the server part (connected to the
client) and the client part (connected to the server) of the proxy.

This architecture makes it easy to implement specific techniques to
cross a given network boundary, possibly by using a proxy on one side
of the network fence, and a reverse-proxy on the other side of the fence.

See L</AVAILABLE CONNECTORS> for details about the existing connectors.

=head1 METHODS

If you only intend to use Net::Proxy and not write new
connectors, you only need to know about C<new()>, C<register()>
and C<mainloop()>.

=head2 Class methods

=head3 new

    my $proxy = Net::Proxy->new( { in => { ... }, { out => { ... } } );

Return a new Net::Proxy object, with two connectors configured
as described in the hashref.

The connector parameters are described in the table below, as well
as in each connector documentation.

=head3 mainloop

    Net::Proxy->mainloop( $max_connections )

This method initialises all the registered C<Net::Proxy> objects
and then loops on all the sockets ready for reading, passing
the data through the various C<Net::Proxy::Connector> objets
to handle the specifics of each connection.

If C<$max_connections> is given, the proxy will stop after having fully
processed that many connections. Otherwise, this method does not return.

=head3 add_listeners

    Net::Proxy->add_listeners( @sockets );

Add the given sockets to the list of listening sockets.

=head3 watch_reader_sockets

    Net::Proxy->watch_reader_sockets( @sockets );

Add the given sockets to the readers watch list.

=head3 watch_writer_sockets

    Net::Proxy->watch_writer_sockets( @sockets );

Add the given sockets to the writers watch list.

=head3 remove_writer_sockets

    Net::Proxy->remove_writer_sockets( @sockets );

Remove the given sockets from the writers watch list.

=head3 close_sockets

    Net::Proxy->close_sockets( @sockets );

Close the given sockets and cleanup the related internal structures.

=head3 set_verbosity

    Net::Proxy->set_verbosity( $level );

Set the logging level. C<0> means not messages except warnings and errors.

=head3 error

    Net::Proxy->error( $message );

Log C<$message> to STDERR, always.

=head3 notice

    Net::Proxy->notice( $message );

Log C<$message> to STDERR if verbosity level is equal to C<1> or more.

=head3 info

    Net::Proxy->info( $message );

Log C<$message> to STDERR if verbosity level is equal to C<2> or more.

=head3 debug

    Net::Proxy->debug( $message );

Log C<$message> to STDERR if verbosity level is equal to C<3> or more.

(Note: throughout the Net::Proxy source code, calls to C<debug()> are
commented with C<##>.)

=head3 get_max_buffer_size

    my $buffsize = Net::Proxy->get_max_buffer_size;

Get the maximum allowed length of the internal write buffers used
by each connector.

=head3 set_max_buffer_size

    Net::Proxy->set_max_buffer_size($buffsize);

Get or set the maximum allowed length of the internal write buffers used
by each connector.  A value of 0 means that the maximum length is not
checked. The default value is 16384 bytes (16kB).

Note that this is a global value, shared by all proxies and connectors.

=head2 Class methods related to sockets

Some of the class methods are related to the socket objects that handle
the actual connections.

=head3 get_peer

    my $peer = Net::Proxy->get_peer( $socket );

Get the socket peer.

=head3 set_peer

    Net::Proxy->set_peer( $socket, $peer );

Set the socket peer.

=head3 get_connector

    my $connector = Net::Proxy->get_connector( $socket );

Get the socket connector (a L<Net::Proxy::Connector> object).

=head3 set_connector

    Net::Proxy->set_connector( $socket, $connector );

Set the socket connector (a L<Net::Proxy::Connector> object).

=head3 get_state

    my $state = Net::Proxy->get_state( $socket );

Get the socket state.

=head3 set_state

    Net::Proxy->set_state( $socket, $state );

Set the socket state. Some C<Net::Proxy::Connector> subclasses
may wish to use this to store some internal information about the
socket or the connection.

=head3 get_nick

    my $nick = Net::Proxy->get_nick( $socket );

Get the socket nickname.

=head3 set_nick

    Net::Proxy->set_nick( $socket, $nickname );

Set the socket nickname. Typically used by L<Net::Proxy::Connector>
to give informative names to socket (used in the log messages).

=head3 get_buffer

    my $buffer = Net::Proxy->get_buffer( $socket );

Get the content of the writing buffer for the socket.

=head3 set_buffer

    Net::Proxy->set_buffer( $socket, $data );

Set the content of the writing buffer for the socket.
Used by L<Net::Proxy::Connector> in C<raw_read_from()> and
C<ranw_write_to()>.

=head3 get_callback

    Net::Proxy->get_callback( $socket );

Get the callback currently associated with the socket.

=head3 set_callback

    Net::Proxy->set_callback( $socket, $coderef );

Set the callback currently associated with the socket.

=head3 add_to_buffer

    Net::Proxy->add_to_buffer( $socket, $data );

Add data to the writing buffer of the socket.

=head2 Instance methods

=head3 register

    $proxy->register();

Register a Net::Proxy object so that it will be included in
the C<mainloop()> processing.

=head3 unregister

    $proxy->unregister();

Unregister the Net::Proxy object.

=head3 in_connector

    my $connector = $proxy->in_connector();

Return the L<Net::Proxy::Connector> objet that handles the incoming
connection and handles the data coming from the "client" side.

=head3 out_connector

    my $connector = $proxy->out_connector();

Return the L<Net::Proxy::Connector> objet that creates the outgoing
connection and handles the data coming from the "server" side.

=head2 Statistical methods

The following methods manage some statistical information
about the individual proxies:

=head3 stat_inc_opened

    $proxy->stat_inc_opened();

Increment the "opened" connection counter for this proxy.

=head3 stat_inc_closed

    $proxy->stat_inc_closed();

Increment the "closed" connection counter for this proxy.

=head3 stat_opened

    my $opened = $proxy->stat_opened();

Return the count of "opened" connections for this proxy.

=head3 stat_closed

    my $closed = $proxy->stat_closed();

Return the count of "closed" connections for this proxy.

=head3 stat_total_opened

    my $opened = $proxy->stat_total_opened();

Return the total count of "opened" connections across all proxy objects.

=head3 stat_total_closed

    my $closed = $proxy->stat_total_closed();

Return the total count of "closed" connections across all proxy objects.

=head1 CONNECTORS

All connection types are provided with the help of specialised classes.
The logic for protocol C<xxx> is provided by the C<Net::Proxy::Connector::xxx>
class.

=head2 Connector hooks

There is a single parameter that all connectors accept: C<hook>.
Given a code reference, the code reference will be called when
data is I<received> on the corresponding socket.

The code reference should have the following signature:

    sub callback {
        my ($dataref, $sock, $connector) = @_;
        ...
    }

C<$dataref> is a reference to the chunk of data received,
C<$sock> is a reference to the socket that received the data, and
C<$connector> is the C<Net::Proxy::Connector> object that created the
socket. This allows someone to eventually store data in a stash stored
in the connector, so as to share data between sockets.

=head2 Available connectors

=over 4

=item tcp (L<Net::Proxy::Connector::tcp>)

This is the simplest possible proxy connector. On the "in" side, it sits waiting
for incoming connections, and on the "out" side, it connects to the
configured host/port.

=item connect (L<Net::Proxy::Connector::connect>)

This proxy connector can connect to a TCP server though a web proxy that
accepts HTTP CONNECT requests.

=item dual (L<Net::Proxy::Connector::dual>)

This proxy connector is a Y-shaped connector: depending on the client behaviour
right after the connection is established, it connects it to one
of two services, handled by two distinct connectors.

=item dummy (L<Net::Proxy::Connector::dummy>)

This proxy connector does nothing. You can use it as a template for writing
new L<Net::Proxy::Connector> classes.

=back

=head2 Summary

This table summarises all the available L<Net::Proxy::Connector>
classes and the parameters their constructors recognise.

C<N/A> means that the given L<Net::Proxy::Connector> cannot be used
in that position (either C<in> or C<out>).

     Connector  | in parameters   | out parameters
    ------------+-----------------+-----------------
     tcp        | host            | host
                | port            | port
    ------------+-----------------+-----------------
     connect    | N/A             | host
                |                 | port
                |                 | proxy_host
                |                 | proxy_port
                |                 | proxy_user
                |                 | proxy_pass
                |                 | proxy_agent
    ------------+-----------------+-----------------
     dual       | host            | N/A
                | port            |
                | timeout         |
                | server_first    |
                | client_first    |
    ------------+-----------------+-----------------
     dummy      | N/A             | N/A
    ------------+-----------------+-----------------
     ssl        | host            | host
                | port            | port
                | start_cleartext | start_cleartext
    ------------+-----------------+-----------------
     connect_ssl| N/A             | host
                |                 | port
                |                 | proxy_host
                |                 | proxy_port
                |                 | proxy_user
                |                 | proxy_pass
                |                 | proxy_agent

L<Net::Proxy::Connector::dummy> is used as the C<out> parameter for
a L<Net::Proxy::Connector::dual>, since the later is linked to two
different connector objects.

=head1 AUTHOR

Philippe 'BooK' Bruhat, C<< <book@cpan.org> >>.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-proxy@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/>. I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 TODO

Here's my own wishlist:

=over 4

=item *

Write a connector fully compatible with GNU httptunnel
(L<http://www.nocrew.org/software/httptunnel.html>).

This one will probably be named C<Net::Proxy::Connector::httptunnel>.

=item *

Enhance the httptunnel protocol to support multiple connections.

=item *

Implement RFC 3093 - Firewall Enhancement Protocol (FEP), as
C<Net::Proxy::Connector::FEP>. This RFC was published on April 1, 2001.

This is probably impossible with Net::Proxy, since the FEP driver is
a rather low-level driver (at the IP level of the network stack).

=item *

Implement DNS tunnel connectors.

See L<http://savannah.nongnu.org/projects/nstx/>,
OzymanDNS, L<http://www.doxpara.com/slides/BH_EU_05-Kaminsky.pdf>.
L<http://thomer.com/howtos/nstx.html> for examples.

=item *

Implement an UDP connector. (Is it feasible?)

=item *

Implement a connector that can be plugged to the STDIN/STDOUT of an
external process, like the C<ProxyCommand> option of OpenSSH.

=item *

Implement C<Net::Proxy::Connector::unix>, for UNIX sockets.

=item *

Implement ICMP tunnel connectors.

See
L<http://www.linuxexposed.com/Articles/Hacking/Case-of-a-wireless-hack.html>,
L<http://sourceforge.net/projects/itun>,
L<http://www.cs.uit.no/~daniels/PingTunnel/>,
L<http://thomer.com/icmptx/> for examples.

Since ICMP implies low-level packet reading and writing, it may not be
possible for Net::Proxy to handle it.

=item *

Look for inspiration in the I<Firewall-Piercing HOWTO>,
at L<http://fare.tunes.org/files/fwprc/>.

Look also here: L<http://gray-world.net/tools/>

=item *

Implement a C<Net::Proxy::Connector::starttls> connector that can upgrade
upgrade a connection to SSL transparently, even if the client or server
doesn't support STARTTLS.

Martin Werthmöller provided a full implementation of a connector that
can handle IMAP connections and upgrade them to TLS if the client sends
a C<STARTTLS> command. My implementation will split this in two parts
L<Net::Proxy::Connector::ssl> and C<Net::Proxy::Connector::starttls>,
that inherits from the former.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Proxy

You can also look for information at:

=over 4

=item The public source repository

L<http://github.com/book/Net-Proxy/>

=item AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Proxy>

=item CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Proxy>

=item RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Proxy>

=item Search CPAN

L<http://search.cpan.org/dist/Net-Proxy>

=back

=head1 COPYRIGHT

Copyright 2006-2014 Philippe 'BooK' Bruhat, All Rights Reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

