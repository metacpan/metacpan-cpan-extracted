package Net::Whois::RIPE;

use 5.006;
use warnings;
use strict;
use IO::Socket::INET;
use IO::Select;
use Iterator;

use constant { SOON                    => 30,
               END_OF_OBJECT_MARK      => "\n\n",
               EOL                     => "\015\012",
               QUERY_KEEPALIVE         => q{-k },
               QUERY_NON_RECURSIVE     => q{-r },
               QUERY_REFERRAL          => q{-R },
               QUERY_GROUPING          => q{-G },
               QUERY_UNFILTERED        => q{-B },
               QUERY_LIST_OBJECTS      => q{-qtypes },
               QUERY_LIST_SOURCES      => q{-qsources },
               QUERY_FETCH_TEMPLATE    => q{-t%s },
               QUERY_LIMIT_OBJECT_TYPE => q{-T%s },
};

=head1 NAME

Net::Whois::RIPE - a pure-Perl implementation of the RIPE Database client.

=head1 VERSION

Version 2.005002

=cut

our $VERSION = 2.005002;

=head1 SYNOPSIS

This is a complete rewrite of version 1.31 of the module, which I inherited
from Paul Gampe during the time I've worked for the RIPE NCC, between Nov 2007
and Feb 2010.

It intends to provide a cleaner, simpler, and complete implementation of a RIPE
Database client.

The usage should remain mostly the same:

  use Net::Whois::RIPE;

  my $whois = Net::Whois::RIPE->new( %options );
  $iterator = $whois->query( 'AS333' );

If you prefer to manipulate full-fledged objects you can now use

  use Net::Whois::Object;

  my @objects = Net::Whois::Object->query( 'AS333' );

From version 2.005000 you can also use the  Net::Whois::Generic interface 
that mimics Net::Whois::Object while offering access to data from other sources
than RIPE (AFRINIC, APNIC)

  use Net::Whois::Object;

  my @objects = Net::Whois::Generic->query( 'ORG-AFNC1-AFRINIC' );

Please see L<Net::Whois::Generic> documentation for more details

Of course, comments are more than welcome. If you believe you can help, please
do not hesitate in contacting me.

=head1 BACKWARD COMPATIBILITY

I've choose to break backwards compatibility with older versions of the L<Net::Whois::RIPE> 
module for several different reasons. I will try to explain and justify them here, as design documentation. 
I will also strive to provide practical solutions for porting problems, if any.

=head2 Architecture

The old module provided it's own L<Iterator> implementation. This was common
practice 10 years ago, when the module was initially written. I believe Perl
has a stable and useful standard implementation of L<Iterators> now, and
adopted it instead of maintaining my own. This allows me to reduce the
necessary code base without losing features.

=head2 Query Options

From release 2.0 onwards, L<Net::Whois::RIPE> will allow almost all query
options understanded by the RIPE Database Server. I bumped in the lack of
options myself, sometimes, and I believe other programmers can also use the
extra features offered.

There are nice, sane defaults provided for most of the options. This should
make it possible for a beginner to just ignore all options and settings and
still be able to make some use of the module.

=head2 Memory Footprint

I had the intention of reducing the memory footprint of this module when doing
heavy-lifting. I still don't have measurements, but that was the idea behind
adopting an L<Iterator> wrapping the L<IO::Socket> used to return results.

=head2 Better Data Structures

A production release of this module will be able to feed a L<RPSL::Parser> with
RPSL objects extracted from the RIPE Database and return full-fledged objects
containing a parsed version of the text (way more useful than a text blob, I
believe). 
L<Net::Whois::Object> (from release 2.00_010) is the first attempt toward this
goal.

  # You can now do
  my @objects = Net::Whois::Object->query( 'AS333' );

  # And manipulate the object the OO ways
  for my $object (@objects) {
    print $object->remarks();
  }

=head1 METHODS

=head2 B<new( %options )>

Constructor. Returns a new L<Net::Whois::RIPE> object with an open connection
to the RIPE Database service of choice (defaulting to C<whois.ripe.net:43>).

The C<%options> hash migth contain configuration options for the RIPE Database
server. Not all options provided by the RIPE Database server are suitable for
this implementation, but the idea is to provide everything someone can show a
use for. The options currently recognized are:

=over 4

=item B<hostname>  (IPv4 address or DNS name. Default is C<whois.ripe.net>)

The hostname or IP address of the service to connect to

=item B<port> (integer, default is C<43>)

The TCP port of the service to connect to

=item B<timeout> (integer, default is C<5>)

The time-out (in seconds) for the TCP connection.

=item B<keepalive> (boolean, default is C<false>)

Wherever we want (C<true>) or not (C<false>) to keep the connection to the
server open. This option implements the functionality available through RIPE
Database's "-k" parameter.

=item B<referral> (boolean, default is C<false>)

When true, prevents the server from using the referral mechanism for domain
lookups, so that the RIPE Database server returns an object in the RIPE
Database with the exact match with the lookup argument, rather than doing a
referral lookup.

=item B<recursive> (boolean, default is C<false>)

When set to C<true>, prevents recursion into queried objects for personal
information. This prevents lots of unsolicited objects from showing up on
queries.

=item B<grouping> (boolean, default is C<false>)

When C<true> enables object grouping in server responses. There's little
utility to enable this option, as the objects will be parsed and returned on a
much reasonable format most of the time. For the brave or more knowledgeable
people that want to have they answers in plain text, this can help stablishing
a 'good' ordering for the RPSL objects returned by a query ('good' is RIPE
NCC's definition of 'good' in this case).

=item B<unfiltered> (boolean, default is C<false>)

When C<true> enables unfiltered object output responses. This produces objects
that can be presented back to the RIPE Database for updating.

=item B<types> (list of valid RIPE Database object types, default is empty, meaning all types)

Restrict the RPSL object types allowed in the response to those in the list.
Using this option will cause the L<Net::Whois::RIPE> object to query the RIPE
Database for the available object types for validating the list. The response
will be cached for speed and bandwidth.

=item B<disconnected> (boolean, default is C<false>)

Prevents the constructor from automatically opening a connection to the service
specified (conneting the socket is the default behavior). When set (C<true>),
the programmer is responsible for calling C<connect> in order to stablish a
connection to the RIPE Database service desired.

=back

=cut

{
    my %default_options = ( hostname     => 'whois.ripe.net',
                            port         => '43',
                            timeout      => 5,
                            keepalive    => 0,
                            referral     => 0,
                            recursive    => 0,
                            grouping     => 1,
                            unfiltered   => 0,
                            types        => undef,
                            disconnected => 0,
    );

    sub new {
        my ( $class, %options ) = @_;
        my %known_options;
        $known_options{$_} = exists $options{$_} ? $options{$_} : $default_options{$_} foreach keys %default_options;

        my $self = bless { __options => \%known_options }, $class;

        $self->connect unless delete $self->{__options}{disconnected};
        return $self;
    }
}

=head2 B<hostname( [$hostname] )>

Accessor to the hostname. Accepts an optional hostname, always return the
current hostname.

=cut

sub hostname {
    my ( $self, $hostname ) = @_;
    $self->{__options}{hostname} = $hostname if defined $hostname;
    return $self->{__options}{hostname};
}

=head2 B<port()>

Accessor to the port. Accepts an optional port, always return the current
port.

=cut

sub port {
    my ( $self, $port ) = @_;
    $self->{__options}{port} = $port if defined $port && $port =~ m{^\d+$};
    return $self->{__options}{port};
}

=head2 B<timeout()>

Accessor to the timeout configuration option. Accepts an optional timeout,
always return the current timeout.

=cut

sub timeout {
    my ( $self, $timeout ) = @_;
    $self->{__options}{timeout} = $timeout
        if defined $timeout && $timeout =~ m{^\d+$};
    return $self->{__options}{timeout};
}

=begin UNDOCUMENTED

=head2 B<__boolean_accessor( $self, $attribute [, $value ] )>

Private method. Shouldn't be used from other modules.

Generic implementation of an accessor for booleans. Receives a reference to the
current instance, the attribute name, and a value to be interpreted under
Perl's boolean rules. Sets or gets the named attribute with the given value.
Always returns the most up-to-date value of the attribute.

=end UNDOCUMENTED

=cut

sub __boolean_accessor {
    my ( $self, $attribute ) = ( shift, shift );
    if ( scalar @_ == 1 ) {
        my $value = shift;
        $self->{__options}{$attribute} = $value ? 1 : 0;
    }
    return $self->{__options}{$attribute};
}

=head2 B<keepalive()>

Accessor to the keepalive configuration option. Accepts an optional keepalive,
always return the current keepalive.

=cut

sub keepalive {
    my $self = shift;
    return $self->__boolean_accessor( 'keepalive', @_ );
}

=head2 B<referral()>

Accessor to the referral configuration option. Accepts an optional referral,
always return the current referral.

=cut

sub referral {
    my $self = shift;
    return $self->__boolean_accessor( 'referral', @_ );
}

=head2 B<recursive()>

Accessor to the recursive configuration option. Accepts an optional recursive,
always return the current recursive.

=cut

sub recursive {
    my $self = shift;
    return $self->__boolean_accessor( 'recursive', @_ );
}

=head2 B<grouping()>

Accessor to the grouping configuration option. Accepts an optional grouping,
always return the current grouping.

=cut

sub grouping {
    my $self = shift;
    return $self->__boolean_accessor( 'grouping', @_ );
}

=head2 B<unfiltered()>

Accessor to the unfiltered configuration option.

=cut

sub unfiltered {
    my $self = shift;
    return $self->__boolean_accessor( 'unfiltered', @_ );
}

=head2 B<connect()>

Initiates a connection with the current object's configuration.

=cut

sub connect {
    my $self = shift;
    my %connection = ( Proto      => 'tcp',
                       Type       => SOCK_STREAM,
                       PeerAddr   => $self->hostname,
                       PeerPort   => $self->port,
                       Timeout    => $self->timeout,
                       Domain     => AF_INET,
                       Multihomed => 1,
    );

    # Create a new IO::Socket object
    my $socket = $self->{__state}{socket} = IO::Socket::INET->new(%connection);
    die q{Can't connect to "} . $self->hostname . ':' . $self->port . qq{". Reason: [$@].\n}
        unless defined $socket;

    # Register $socket with the IO::Select object
    if ( my $ios = $self->ios ) {
        $ios->add($socket) unless $ios->exists($socket);
    } else {
        $self->{__state}{ioselect} = IO::Select->new($socket);
    }

    # Set RIPE Database's "keepalive" capability
    $self->send(QUERY_KEEPALIVE) if $self->keepalive;
}

=head2 B<ios()>

Accessor to the L<IO::Select> object coordinating the I/O to the L<IO::Socket>
object used by this module to communicate with the RIPE Database Server. You
shouldn't use this object, but the L</"send()"> and L<"query( $query_string )">
methods instead.

=cut

sub ios { return $_[0]->{__state}{ioselect} }

=head2 B<socket()>

Read-only accessor to the L<IO::Socket> object used by this module.

=cut

sub socket { return $_[0]->{__state}{socket} }

=head2 B<send()>

Sends a message to the RIPE Database server instance to which we're connected
to. Dies if it cannot write, or if there's no open connection to the server.

Return C<true> if the message could be written to the socket, C<false>
otherwise.

=cut

sub send {
    my ( $self, $message ) = @_;
    die q{Not connected} unless $self->is_connected;
    if ( $self->ios->can_write( SOON + $self->timeout ) ) {
        $self->socket->print( $message, EOL );
        $self->socket->flush;
        return 1;
    }
    return 0;
}

=head2 B<reconnect()>

Reconnects to the server in case we lost connection.

=cut

sub reconnect {
    my $self = shift;
    $self->disconnect if $self->is_connected;
    $self->connect;
}

=head2 B<disconnect()>

Disconnects this client from the server. This renders the client useless until
you call L</"connect()"> again. This method is called by L</DESTROY()> as part of
an object's clean-up process.

=cut

sub disconnect {
    my $self = shift;
    if ( $self->is_connected ) {
        my $socket = $self->{__state}{socket};
        $socket->close;
        $self->{__state}{ioselect}->remove($socket)
            if $self->{__state}{ioselect};
        delete $self->{__state}{socket};
    }
}

=head2 B<is_connected()>

Returns C<true> if this instance is connected to the RIPE Database service
configured.

=cut

sub is_connected {
    my $self   = shift;
    my $socket = $self->socket;
    return UNIVERSAL::isa( $socket, 'IO::Socket' )
        && $socket->connected ? 1 : 0;
}

=head2 B<DESTROY()>

Net::Whois::RIPE object destructor. Called by the Perl interpreter upon
destruction of an instance.

=cut

sub DESTROY {
    my $self = shift;
    $self->disconnect;
}

=head2 B<query( $query_string )>

Sends a query to the server. Returns an L<Iterator> object that will return one RPSL block at a time.

=cut

# TODO: Identify and ignore comments within the Iterator scope?
# TODO: Identify and rise as soon as possible "%ERROR:\d+:.+" results.

sub query {
    my ( $self, $query ) = @_;
    my $parameters = "";
    $parameters .= q{ } . QUERY_KEEPALIVE  if $self->keepalive;
    $parameters .= q{ } . QUERY_UNFILTERED if $self->unfiltered;
    $parameters .= q{ } . QUERY_NON_RECURSIVE unless $self->recursive;
    $parameters .= q{ } . QUERY_REFERRAL if $self->referral;
    my $fullquery = $parameters . $query;
    return $self->__query($fullquery);
}

# Allows me to pass in queries without having all the automatic options added
# up to it.
sub __query {
    my ( $self, $query ) = @_;
    $self->reconnect unless $self->keepalive;
    die "Not connected" unless $self->is_connected;

    if ( $self->ios->can_write( SOON + $self->timeout ) ) {
        $self->socket->print( $query, EOL );

        return Iterator->new(
            sub {
                local $/ = "\n\n";
                if ( $self->ios->can_read( SOON + $self->timeout ) ) {
                    my $block = $self->socket->getline;
                    return $block if defined $block;
                }
                Iterator::is_done;
            }
        );
    }
}

=head2 B<object_types()>

Return a list of known object types from the RIPE Database.

RIPE currently returns 21 types (Limerik have been removed):
as-block as-set aut-num domain filter-set inet6num inetnum inet-rtr irt
key-cert mntner organisation peering-set person poem poetic-form role route
route6 route-set rtr-set

Due to some strange mis-behaviour in the protocol (or documentation?) the RIPE
Database server won't allow a keep-alive token with this query, meaning the
connection will be terminated after this query.

=cut

sub object_types {
    my $self     = shift;
    my $iterator = $self->__query(QUERY_LIST_OBJECTS);
    while ( !$iterator->is_exhausted ) {
        my $value = $iterator->value;
        return split /\s+/, $value if $value !~ /^%\s/;
    }
    return;
}

=head1 AUTHOR

Luis Motta Campos, C<< <lmc at cpan.org> >>

=head1 CAVEATS

=over 4

=item B<No IPv6 Support>

There's no support for IPv6 still on this module. I'm planning to add it in a
future version.

=item B<Tests Depend On Connectivity>

As this is the initial alpha release, there is still some work to do in terms
of testing. One of the first things I must work on is to eliminate the
dependency on connectivity to the RIPE Database.

=item B<Current Interface is not Backwards-Compatible>

I plan to implement a drop-in replacement to the old interface soon, as an extension to this module. For now, this module just breaks compatibility with the old interface. Please read the full discussion about compatibility with older version of the L<NET::Whois::RIPE> in the L</"BACKWARD COMPATIBILITY"> section.

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-whois-ripe at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=net-whois-ripe>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Whois::RIPE


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=net-whois-ripe>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/net-whois-ripe>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/net-whois-ripe>

=item * Search CPAN

L<http://search.cpan.org/dist/net-whois-ripe>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Paul Gampe and Kevin Backer for writing previous versions of this
module;

Thanks to Paul Gampe for allowing me to handle me the maintenance of this
module on CPAN;

Thanks to RIPE NCC for allowing me to work on this during some of my office
hours.

Thanks to Carlos Fuentes for the nice patch with bugfixes for version 2.00_008.

Thanks to Moritz Lenz for all his contributions
Thanks to Noris Network AG for allowing him to contribute to this module.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Luis Motta Campos, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
