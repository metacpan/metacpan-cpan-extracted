package Net::Whois::Generic;

use 5.006;
use warnings;
use strict;
use IO::Socket::INET;
use IO::Select;
use Iterator;
use Net::Whois::Object;
use Data::Dumper;

use constant {
	SOON               => 30,
	END_OF_OBJECT_MARK => "\n\n",
	EOL                => "\015\012",
	QUERY_LIST_OBJECTS => q{-qtypes },
};

# simplify if all servers happen to accept same options
our %RIR = (
	apnic   => { SERVER => 'whois.apnic.net',   QUERY_NON_RECURSIVE => q{-r }, QUERY_REFERRAL => q{-R }, QUERY_UNFILTERED => q{-B }, },
	ripe    => { SERVER => 'whois.ripe.net',    QUERY_NON_RECURSIVE => q{-r }, QUERY_REFERRAL => q{-R }, QUERY_UNFILTERED => q{-B }, },
	arin    => { SERVER => 'whois.arin.net',    QUERY_NON_RECURSIVE => q{-r }, QUERY_REFERRAL => q{-R }, QUERY_UNFILTERED => q{-B }, },
	lacnic  => { SERVER => 'whois.lacnic.net',  QUERY_NON_RECURSIVE => q{-r }, QUERY_REFERRAL => q{-R }, QUERY_UNFILTERED => q{-B }, },
	afrinic => { SERVER => 'whois.afrinic.net', QUERY_NON_RECURSIVE => q{-r }, QUERY_REFERRAL => q{-R }, QUERY_UNFILTERED => q{-B }, },
);

=head1 NAME

Net::Whois::Generic - a pure-Perl implementation of a multi source Whois client.

=head1 VERSION

Version 2.005001

=cut

our $VERSION = 2.005001;

=head1 SYNOPSIS

Net::Whois::Generic is my first attempt to unify Whois information from different sources.
Historically Net::Whois::RIPE was the first written, then Net::Whois::Object was added to provide
a RPSL encapsultation of the data returned from RIPE database, with an API more object oriented.

Net::Whois::Generic is a new interface designed to be more generic and to encapsulate data from 
various sources (RIPE, but also AFRINIC, APNIC...)
The current implementation is barely a proof of concept, AFRINIC and APNIC are the only other sources implemented,
but I expect to turn it into a generic/robust implementation based on the users feedback.

Usage is very similar to the Net::Whois::Object :

    my $c = Net::Whois::Generic->new( disconnected => 1, unfiltered => 1 );

    my ($org) = $c->query( 'ORG-AFNC1-AFRINIC', { type => 'organisation' } );
    # $org is a 'Net::Whois::Object::Organisation::AFRINIC' object;
    
    
    my @o = $c->query('101.0.0.0/8');
    # @o contains various Net::Whois::Object:Inetnum::APNIC, and Net::Whois::Object::Information objects

As Net::Whois::Generic started as an improvment of Net::Whois::RIPE, and have a good amount of code in common,
for this reason (and some others) it is currently bundled inside the the Net::Whois::RIPE package.
This might change in the future although.

=head1 METHODS

=head2 B<new( %options )>

Constructor. Returns a new L<Net::Whois::Generic> object with an open connection
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
Using this option will cause the L<Net::Whois::Generic> object to query the RIPE
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
	my %default_options = (
		hostname     => 'whois.ripe.net',
		port         => '43',
		timeout      => 5,
		referral     => 0,
		recursive    => 0,
		grouping     => 1,
		unfiltered   => 0,
		types        => undef,
		disconnected => 0,
	);

	sub new
	{
		my $class = shift;

		# I wish I hadn't to maintain backward compatibility but 2 forms exist...
		my %options;

		if (ref($_[0]) =~ /HASH/i) {
			%options = %{ $_[0] };
		}
		else {
			%options = @_;
		}
		my %known_options;
		$known_options{$_} = exists $options{$_} ? $options{$_} : $default_options{$_} foreach keys %default_options;

		my $self = bless { __options => \%known_options }, $class;

		return $self;
	}
}

=head2 B<hostname( [$hostname] )>

Accessor to the hostname. Accepts an optional hostname, always return the
current hostname.

=cut

sub hostname
{
	my ($self, $hostname) = @_;
	$self->{__options}{hostname} = $hostname if defined $hostname;
	return $self->{__options}{hostname};
}

=head2 B<port()>

Accessor to the port. Accepts an optional port, always return the current
port.

=cut

sub port
{
	my ($self, $port) = @_;
	$self->{__options}{port} = $port if defined $port && $port =~ m{^\d+$};
	return $self->{__options}{port};
}

=head2 B<timeout()>

Accessor to the timeout configuration option. Accepts an optional timeout,
always return the current timeout.

=cut

sub timeout
{
	my ($self, $timeout) = @_;
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

sub __boolean_accessor
{
	my ($self, $attribute) = (shift, shift);
	if (scalar @_ == 1) {
		my $value = shift;
		$self->{__options}{$attribute} = $value ? 1 : 0;
	}
	return $self->{__options}{$attribute};
}

=head2 B<referral()>

Accessor to the referral configuration option. Accepts an optional referral,
always return the current referral.

=cut

sub referral
{
	my $self = shift;
	return $self->__boolean_accessor('referral', @_);
}

=head2 B<recursive()>

Accessor to the recursive configuration option. Accepts an optional recursive,
always return the current recursive.

=cut

sub recursive
{
	my $self = shift;
	return $self->__boolean_accessor('recursive', @_);
}

=head2 B<grouping()>

Accessor to the grouping configuration option. Accepts an optional grouping,
always return the current grouping.

=cut

sub grouping
{
	my $self = shift;
	return $self->__boolean_accessor('grouping', @_);
}

=head2 B<unfiltered()>

Accessor to the unfiltered configuration option.

=cut

sub unfiltered
{
	my $self = shift;
	return $self->__boolean_accessor('unfiltered', @_);
}

=head2 B<connect()>

Initiates a connection with the current object's configuration.

=cut

sub connect
{
	my $self       = shift;
	my %connection = (
		Proto      => 'tcp',
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
	if (my $ios = $self->ios) {
		$ios->add($socket) unless $ios->exists($socket);
	}
	else {
		$self->{__state}{ioselect} = IO::Select->new($socket);
	}
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

sub send
{
	my ($self, $message) = @_;
	die q{Not connected} unless $self->is_connected;
	if ($self->ios->can_write(SOON + $self->timeout)) {
		$self->socket->print($message, EOL);
		$self->socket->flush;
		return 1;
	}
	return 0;
}

=head2 B<reconnect()>

Reconnects to the server in case we lost connection.

=cut

sub reconnect
{
	my $self = shift;
	$self->disconnect if $self->is_connected;
	$self->connect;
}

=head2 B<disconnect()>

Disconnects this client from the server. This renders the client useless until
you call L</"connect()"> again. This method is called by L</DESTROY()> as part of
an object's clean-up process.

=cut

sub disconnect
{
	my $self = shift;
	if ($self->is_connected) {
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

sub is_connected
{
	my $self   = shift;
	my $socket = $self->socket;
	return UNIVERSAL::isa($socket, 'IO::Socket')
		&& $socket->connected ? 1 : 0;
}

=head2 B<DESTROY()>

Net::Whois::Generic object destructor. Called by the Perl interpreter upon
destruction of an instance.

=cut

sub DESTROY
{
	my $self = shift;
	$self->disconnect;
}

=head2 B<_find_rir( $query_string )>

Guess the associated RIR based on the query.

=cut

sub _find_rir
{
	my ($self, $query) = @_;

	my $rir;

	if (       ($query =~ /^(41|102|105|154|196|197)\.\d+\.\d+\.\d+/)
		or ($query =~ /AFRINIC/i)
		or ($query =~ /^2c00::/i))
	{
		$rir = 'afrinic';
	}
	elsif ( (          $query =~ /^(23|34|50|64|64|65|66|67|68|69|70|71|72|73|74|75|76|96|97|98|9|100|104|107|108|135|136|142|147|162|166|172|173|174|184|192|198|199|204|205|206|207|208|209|216)/
			or ($query =~ /^(2001:0400|2001:1800|2001:4800:|2600|2610:0000):/i)
			or $query =~ /ARIN/
		)
		)
	{
		$rir = 'arin';

	}
	elsif ( (          $query =~ /^(10|14|27|36|39|42|49|58|59|60|61|101|103|106|110|111|112|113|114|115|116|117|118|119|120|121|122|123|124|125|126|169\.208|175|180|182|183|202|203|210|211|218|219|220|221|222|223)\.\d+\.\d+/
			or ($query =~ /^(2001:0200|2001:0C00|2001:0E00|2001:4400|2001:8000|2001:A000|2001:B000|2400:0000|2001:0DC0|2001:0DE8|2001:0DF0|2001:07FA|2001:0DE0|2001:0DB8):/i)
			or $query =~ /APNIC/
		)
		)
	{
		$rir = 'apnic';

	}
	else {
		$rir = 'ripe';
	}

	return $rir;
}

=head2 B<adapt_query( $query_string[, $rir] )>

Adapt a query to set various parameter (whois server, query options...) based on the query.
Takes an optional parameter $rir, to force a specific RIR to be used.

=cut

sub adapt_query
{
	my ($self, $query, $rir) = @_;
	my $fullquery;

	# determine RIR unless $rir;
	$rir = $self->_find_rir($query) unless $rir;

	if ($rir eq 'ripe') {
		$self->hostname($RIR{ripe}{SERVER});
	}
	elsif ($rir eq 'afrinic') {
		$fullquery = '-V Md5.0 ' . $query;
		$self->hostname($RIR{afrinic}{SERVER});
	}
	elsif ($rir eq 'arin') {
		$self->hostname($RIR{arin}{SERVER});
	}
	elsif ($rir eq 'lacnic') {
		$self->hostname($RIR{lacnic}{SERVER});
	}
	elsif ($rir eq 'apnic') {
		$self->hostname($RIR{apnic}{SERVER});
	}

	my $parameters = "";
	$parameters .= q{ } . $RIR{$rir}{QUERY_UNFILTERED} if $self->unfiltered;
	$parameters .= q{ } . $RIR{$rir}{QUERY_NON_RECURSIVE} unless $self->recursive;
	$parameters .= q{ } . $RIR{$rir}{QUERY_REFERRAL} if $self->referral;
	$fullquery = $parameters . $query;

	return $fullquery;
}

=head2 B<query( $query, [\%options] )>

 ******************************** EXPERIMENTAL ************************************
   This method is a work in progress, the API and behaviour are subject to change
 **********************************************************************************

Query the the appropriate RIR database and return Net::Whois::Objects

This method accepts 2 optional parameters

'type' which is a regex used to filter the query result:
Only the object whose type matches the 'type' parameter are returned

'attribute' which is a regex used to filter the query result:
Only the value of the attributes matching the 'attribute' parameter are
returned

Note that if 'attribute' is specified strings are returned, instead of
Net::Whois::Objects

Net::Whois:Generic->query() deprecates  Net::Whois::Object->query() since release 2.005 of Net::Whois::RIPE

=cut

sub query
{
	my ($self, $query, $options) = @_;

	my $attribute;
	my $type;
	my $response;

	for my $opt (keys %$options) {
		if ($opt =~ /^attribute$/i) {
			$attribute = $options->{$opt};
		}
		elsif ($opt =~ /^type$/i) {
			$type = $options->{$opt};
		}
	}

	if (!ref $self) {

		# $self is the class
		$self = $self->new($options);
	}

	$query = $self->adapt_query($query);
	my $iterator = $self->__query($query);

	my @objects = Net::Whois::Object->new($iterator);

	($response) = grep { ref($_) =~ /response/i } @objects;

	if ($response) {
		$self->_process_response($response);

	}

	if ($type) {
		@objects = grep { ref($_) =~ /$type/i } @objects;
	}

	if ($attribute) {
		return grep {defined} map {
			my $r;
			eval { $r = $_->$attribute };
			$@ ? undef : ref($r) eq 'ARRAY' ? @$r : $r
		} @objects;
	}
	else {
		return grep {defined} @objects;
	}
}

# Allows me to pass in queries without having all the automatic options added
# up to it.
sub __query
{
	my ($self, $query) = @_;

	$self->connect;

	# die "Not connected" unless $self->is_connected;

	if ($self->ios->can_write(SOON + $self->timeout)) {
		$self->socket->print($query, EOL);

		return Iterator->new(
			sub {
				local $/ = END_OF_OBJECT_MARK;
				if ($self->ios->can_read(SOON + $self->timeout)) {
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

sub object_types
{
	my $self     = shift;
	my $iterator = $self->__query(QUERY_LIST_OBJECTS);
	while (!$iterator->is_exhausted) {
		my $value = $iterator->value;
		return split /\s+/, $value if $value !~ /^%\s/;
	}
	return;
}

=head2 B<_process_response( $response )>

Process a response (error code, error message...)

=cut

sub _process_response
{
	my $self     = shift;
	my $response = shift;
	my $code;
	my $msg;

	eval { $response->comment };
	die "Dump : " . Dumper $response if $@;

	if ($response->response =~ /ERROR.*:.*?(\d+)/) {
		$code = $1;
		$msg = join '', $response->comment();
	}
}

=head1 AUTHOR

Arnaud "Arhuman" Assad, C<< <arhuman at gmail.com> >>

=head1 CAVEATS

=over 4

=item B<Update>

Update of objects from database other than RIPE is not currently implemented...

=item B<Sources>

Currently the only sources implemented are RIPE, AFRINIC, and APNIC.

=item B<Maturity>

The Net::Whois::Generic interface is highly experimental.
There are probably bugs, without any doubt missing documentation and
examples but please don't hesitate to contact me to suggest corrections
and improvments.

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-whois-ripe at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=net-whois-ripe>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SEE ALSO

There are several tools similar to L<Net::Whois::Generic>, I'll list some of them below and some reasons why Net::Whois::Generic exists anyway:

L<Net::Whois::IANA> - A universal WHOIS extractor: update not possible, no RPSL parser

L<Net::Whois::ARIN> - ARIN whois client: update not possible, only subset of ARIN objects handled

L<Net::Whois::Parser> - Module for parsing whois information: no query handling, parser can (must?) be added

L<Net::Whois::RIPE> - RIPE whois client: the basis for L<Net::Whois::Generic> but only handle RIPE.
   
=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Whois::Generic

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

Thanks to Jaguar Networks which grants me time to work on this module.

=head1 COPYRIGHT & LICENSE

Copyright 2013 Arnaud "Arhuman" Assad, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
