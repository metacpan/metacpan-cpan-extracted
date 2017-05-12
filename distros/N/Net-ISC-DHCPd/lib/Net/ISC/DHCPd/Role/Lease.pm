package Net::ISC::DHCPd::Role::Lease;

=head1 NAME

Net::ISC::DHCPd::Role::Lease - Role for dhcpd lease

=head1 DESCRIPTION

See L<Net::ISC::DHCPd::Leases::Lease>, L<Net::ISC::DHCPd::OMAPI::Lease>
and L<Net::ISC::DHCPd::OMAPI::Actions>.

=cut

use Moose::Role;
use Net::ISC::DHCPd::OMAPI::Sugar;

=head1 ATTRIBUTES

=head2 atsfp

 $int = $self->atsfp;
 $self->atsfp($int);

The actual tsfp value sent from the peer. This value is forgotten when a
lease binding state change is made, to facillitate retransmission logic.

Actions: examine.

=cut

omapi_attr atsfp => (
    isa => Time,
    actions => [qw/examine/],
);

=head2 billing_class

 ?? = $self->billing_class;
 $self->billing_class(??);

The handle to the class to which this lease is currently billed,
if any (The class object is not currently supported).

Actions: none.

=cut

omapi_attr billing_class => (
    isa => 'Any',
);

=head2 circuit_id

 $str => $self->circuit_id;
 $self->circuit_id($str);

Circuit ID from Relay Agent Option 82.

=cut

omapi_attr circuit_id => (
    is => 'rw',
    isa => 'Str',
);

=head2 client_hostname

 $self->client_hostname($str);
 $str = $self->client_hostname;

The value the client sent in the host-name option.

Actions: examine, modify.

=cut

omapi_attr client_hostname => (
    isa => 'Str',
    actions => [qw/examine modify/],
);

=head2 cltt

 $int = $self->cltt;
 $self->cltt($int);

The time of the last transaction with the client on this lease.

Actions: examine.

=cut

omapi_attr cltt => (
    isa => Time,
    actions => [qw/examine/],
);

=head2 dhcp_client_identifier

 $self->dhcp_client_identifier(??);
 ?? = $self->dhcp_client_identifier;

The client identifier that the client used when it acquired the lease.
Not all clients send client identifiers, so this may be empty.

Actions: examine, lookup, modify.

=cut

omapi_attr dhcp_client_identifier => (
    isa => 'Str',
    actions => [qw/examine lookup modify/],
);

=head2 ends

 $self->ends($int);
 $int = $self->ends;

The time when the current state of the lease ends, as understood by the client.
Setting this to "0" will effectively makes the DHCP server drop the lease.

Actions: examine, modify.

Note: This attribute can only be modified from ISC-DHCP-4.1.0.

=cut

omapi_attr ends => (
    isa => Time,
    actions => [qw/examine modify/],
);

=head2 flags

 ?? = $self->flags;
 $self->flags(??);

Actions: none.

=cut

omapi_attr flags => (
    isa => 'Str',
);

=head2 host

 $self->host(??);
 ?? = $self->host;

The host declaration associated with this lease, if any.

Actions: examine.

=cut

omapi_attr host => (
    isa => 'Any',
    actions => [qw/examine/],
);

=head2 ip_address

 $self->ip_address($ip_addr_obj);
 $self->ip_address("127.0.0.1"); # standard ip
 $self->ip_address("22:33:aa:bb"); # hex
 $std_ip_str = $self->ip_address;

The IP address of the lease.

Actions: examine, lookup.

=cut

omapi_attr ip_address => (
    isa => Ip,
    actions => [qw/examine lookup/],
);

=head2 pool

 ?? = $self->pool;
 $self->pool(??);

The pool object associted with this lease (The pool object is not
currently supported).

Actions: examine.

=cut

omapi_attr pool => (
    isa => 'Any',
    actions => [qw/examine/],
);

=head2 remote_id

 $str = $self->remote_id;
 $self->remote_id($str);

Remote ID from Relay Agent Option 82.

=cut

omapi_attr remote_id => (
    is => 'rw',
    isa => 'Str',
);

=head2 starts

 $self->starts($int);
 $int = $self->starts;

The time when the lease's current state ends, as understood by the server.

Actions: examine.

=cut

omapi_attr starts => (
    isa => Time,
    actions => [qw/examine/],
);

=head2 state

 $self->state($str);
 $str = $self->state;

Valid states: free, active, expired, released, abandoned, reset, backup,
reserved, bootp.

Actions: examine, lookup.

=cut

omapi_attr state => (
    isa => State,
    actions => [qw/examine lookup/],
);

=head2 subnet

 ?? = $self->subnet;
 $self->subnet(??);

The subnet object associated with this lease. (The subnet object is not
currently supported).

Actions: examine.

=cut

omapi_attr subnet => (
    isa => 'Any',
    actions => [qw/examine/],
);

=head2 tsfp

 $self->tsfp($int);
 $int = $self->tsfp;

The adjusted time when the lease's current state ends, as understood by
the failover peer (if there is no failover peer, this value is undefined).
Generally this value is only adjusted for expired, released, or reset
leases while the server is operating in partner-down state, and otherwise
is simply the value supplied by the peer.

Actions: examine.

=cut

omapi_attr tsfp => (
    isa => Time,
    actions => [qw/examine/],
);

=head2 tstp

 $self->tstp($int);
 $int = $self->tstp;

The time when the lease's current state ends, as understood by the server.

Actions: examine.

=cut

omapi_attr tstp => (
    isa => Time,
    actions => [qw/examine/],
);

=head2 hardware_address

 $self->hardware_address($str);
 $str = $self->hardware_address;

The hardware address (chaddr) field sent by the client when it acquired
its lease.

Actions: examine, modify.

=cut

omapi_attr hardware_address => (
    isa => Mac,
    actions => [qw/examine lookup modify/],
);

=head2 hardware_type

 $self->hardware_type($str);
 $str = $self->hardware_type;

The type of the network interface that the client reported when it
acquired its lease.

Actions: examine, modify.

=cut

omapi_attr hardware_type => (
    isa => HexInt,
    actions => [qw/examine modify/],
);

=head1 ACKNOWLEDGEMENTS

Most of the documentation is taken from C<dhcpd(8)>.

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut

1;
