package Net::ISC::DHCPd::OMAPI::Failover;

=head1 NAME

Net::ISC::DHCPd::OMAPI::Failover - OMAPI failover state class

=head1 SEE ALSO

L<Net::ISC::DHCPd::OMAPI::Actions>.
L<Net::ISC::DHCPd::OMAPI::Meta::Attribute>.

=head1 SYNOPSIS

 use Net::ISC::DHCPd::OMAPI;

 $omapi = Net::ISC::DHCPd::OMAPI->new(...);
 $omapi->connect
 $failover = $omapi->new_object("failover", { $attr => $value });
 $failover->$attr($value); # same as in constructor
 $failover->read; # retrieve server information
 $failover->write; # write to server

=cut

use Net::ISC::DHCPd::OMAPI::Sugar;
use Moose;

with 'Net::ISC::DHCPd::OMAPI::Actions';

=head1 ATTRIBUTES

=head2 name

 $self->name($name);
 $str = $self->name;

Indicates the name of the failover peer relationship, as described in
the server's dhcpd.conf file.

Actions: examine.

=cut

omapi_attr name => (
    isa => 'Str',
    actions => [qw/examine/],
);

=head2 partner_address

 $self->partner_address($str);
 $str = $self->partner_address;

Indicates the failover partner's IP address.

Actions: examine.

=head2 local_address

 $self->local_address($str);
 $str = $self->local_address;

Indicates the IP address that is being used by the DHCP server for this
failover pair.

Actions: examine.

=cut

omapi_attr [qw/partner_address local_address/] => (
    isa => Ip,
    actions => [qw/examine/],
);

=head2 partner_port

 $self->partner_port($int);
 $int = $self->partner_port;

Indicates the TCP port on which the failover partner is  listening for
failover protocol connections.

Actions: examine.

=head2 local_port

 $self->local_port($int);
 $int = $self->local_port;

Indicates the TCP port on which the DHCP server is listening for failover
protocol connections for this failover pair.

Actions: examine.

=cut

omapi_attr [qw/partner_port local_port/] => (
    isa => 'Int',
    actions => [qw/examine/],
);

=head2 max_outstanding_updates

 $self->max_outstanding_updates($int);
 $int = $self->max_outstanding_updates;

Indicates the number of updates that can be outstanding and unacknowledged
at any given time, in this failover relationship.

Actions: examine.

=cut

omapi_attr max_outstanding_updates => (
    isa => Ip,
    actions => [qw/examine/],
);

=head2 mclt

 $self->mclt($int);
 $int = $self->mclt;

Indicates the maximum client lead time in this failover relationship.

Actions: examine.

=cut

omapi_attr mclt => (
    isa => 'Int',
    actions => [qw/examine/],
);

=head2 load_balance_mac_secs

 $self->load_balance_mac_secs($int);
 $int = $self->load_balance_mac_secs;

Indicates the maximum value for the secs field in a client request before
load balancing is bypassed.

Actions: examine.

=cut

omapi_attr load_balance_mac_secs => (
    isa => 'Int',
    actions => [qw/examine/],
);

=head2 load_balance_hba

 $self->load_balance_hba($str);
 $str = $self->load_balance_hba;

Indicates the load balancing hash bucket array for this failover relationship.

Actions: examine.

=cut

omapi_attr load_balance_hba => (
    isa => 'Str',
    actions => [qw/examine/],
);

=head2 local_state

 $self->local_state($int);
 $self->local_state($str);
 $str = $self->local_state;

Indicates the present state of the DHCP server in this failover relationship.
Possible values for state are:

 1  - partner down
 2  - normal
 3  - communications interrupted
 4  - resolution interrupted
 5  - potential conflict
 6  - recover
 7  - recover done
 8  - shutdown
 9  - paused
 10 - startup
 11 - recover wait

In  general it is not a good idea to make changes to this state. However,
in the case that the failover partner is known to be down, it can be
useful to set the DHCP server's failover state to partner down. At this
point the DHCP server will take over service of the failover partner's
leases as soon as possible, and will give out normal leases, not leases
that are restricted by MCLT. If you do put the DHCP server into the
partner-down when the other DHCP server is not in the partner-down state,
but is not reachable, IP address  assignment conflicts are possible, even
likely. Once a server has been put into partner-down mode, its failover
partner must not be brought back online until communication is possible
between the two servers.

Actions: examine, modify.

=cut

omapi_attr local_state => (
    isa => FailoverState,
    actions => [qw/examine modify/],
);

=head2 partner_state

 $self->partner_state($int);
 $self->partner_state($str);
 $str = $self->partner_state;

Indicates the present state of the failover partner.

Actions: examine.

=cut

omapi_attr partner_state => (
    isa => FailoverState,
    actions => [qw/examine/],
);

=head2 local_stos

 $self->local_stos($int);
 $int = $self->local_stos;

Indicates the time at which the DHCP server entered its present state
in this failover relationship.

Actions: examine.

=head2 partner_stos

 $self->partner_stos($str);
 $str = $self->partner_stos;

Indicates the time at which the failover partner entered its present state.

Actions: examine.

=cut

omapi_attr [qw/local_stos partner_stos/] => (
    isa => Time,
    actions => [qw/examine/],
);

=head2 hierarchy

 $self->hierarchy($int);
 $int = $self->hierarchy;

Indicates whether the DHCP server is primary (0) or secondary (1)
in this failover relationship.

Actions: examine.

See L</is_primary>.

=cut

omapi_attr hierarchy => (
    isa => 'Int',
    actions => [qw/examine/],
);

=head2 last_packet_sent

 $self->last_packet_sent($time);
 $time = $self->last_packet_sent;

Indicates the time at which the most recent failover packet was sent by
this DHCP server to its failover partner.

Actions: examine.

=cut

omapi_attr last_packet_sent => (
    isa => Time,
    actions => [qw/examine/],
);

=head2 last_timestamp_received

 $self->last_timestamp_received($str);
 $str = $self->last_timestamp_received;

Indicates the timestamp that was on the failover message most recently
received from the failover partner.

Actions: examine.

=cut

omapi_attr last_timestamp_received => (
    isa => Time,
    actions => [qw/examine/],
);

=head2 skew

 $self->skew($int);
 $int = $self->skew;

Indicates the skew between the failover partner's clock and this DHCP
server's clock

Actions: examine.

=cut

omapi_attr skew => (
    isa => 'Int',
    actions => [qw/examine/],
);

=head2 max_response_delay

 $self->max_response_delay($int);
 $int = $self->max_response_delay;

Indicates the time in seconds after  which, if no message is received
from the failover partner, the partner is assumed to be out of communication.

Actions: examine.

=cut

omapi_attr max_response_delay => (
    isa => 'Int',
    actions => [qw/examine/],
);

=head2 cur_unacked_updates

 $self->cur_unacked_updates($int);
 $int = $self->cur_unacked_updates;

Indicates the number of update messages that have been received from
the failover partner but not yet processed.

Actions: examine.

=cut

omapi_attr cur_unacked_updates => (
    isa => 'Int',
    actions => [qw/examine/],
);

=head1 METHODS

=head2 is_primary

 $bool = $self->is_primary;

=cut

sub is_primary {
    confess "not implemented";
}

=head1 ACKNOWLEDGEMENTS

Most of the documentation is taken from C<dhcpd(8)>.

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut
__PACKAGE__->meta->make_immutable;
1;
