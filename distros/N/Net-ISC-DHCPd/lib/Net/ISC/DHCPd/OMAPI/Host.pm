package Net::ISC::DHCPd::OMAPI::Host;

=head1 NAME

Net::ISC::DHCPd::OMAPI::Host - OMAPI host class

=head1 SEE ALSO

L<Net::ISC::DHCPd::OMAPI::Actions>.
L<Net::ISC::DHCPd::OMAPI::Meta::Attribute>.

=head1 SYNOPSIS

 use Net::ISC::DHCPd::OMAPI;

 $omapi = Net::ISC::DHCPd::OMAPI->new(...);
 $omapi->connect
 $host = $omapi->new_object("host", { $attr => $value });
 $host->read; # retrieve server information
 $host->$attr($value); # update a value
 $host->write; # write to server

=cut

use Net::ISC::DHCPd::OMAPI::Sugar;
use Moose;

with 'Net::ISC::DHCPd::OMAPI::Actions';

=head1 ATTRIBUTES

=head2 dhcp_client_identifier

 $self->dhcp_client_identifier(??);
 ?? = $self->dhcp_client_identifier;

The client identifier that the client used when it acquired the host.
Not all clients send client identifiers, so this may be empty.

Actions: examine, lookup, modify.

=cut

omapi_attr dhcp_client_identifier => (
    isa => 'Str',
    actions => [qw/examine lookup modify/],
);

=head2 group

 $self->group(??);
 ?? = $self->group;

The named group associated with the host declaration, if there  is one.

Actions: examine, modify.

=cut

omapi_attr group => (
    isa => 'Any',
    actions => [qw/examine modify/],
);

=head2 hardware_address

 $self->hardware_address($str);
 $str = $self->hardware_address;

The hardware address (chaddr) field sent by the client when it acquired
its host.

Actions: examine, lookup, modify.

=cut

omapi_attr hardware_address => (
    isa => Mac,
    actions => [qw/examine lookup modify/],
);

=head2 hardware_type

 $self->hardware_type($str);
 $str = $self->hardware_type;

The type of the network interface that the client reported when it
acquired its host.

Actions: examine, lookup, modify.

=cut

omapi_attr hardware_type => (
    isa => HexInt,
    actions => [qw/examine lookup modify/],
);

=head2 ip_address

 $self->ip_address($ip_addr_obj);
 $self->ip_address("127.0.0.1"); # standard ip
 $self->ip_address("22:33:aa:bb"); # hex
 $std_ip_str = $self->ip_address;

The IP address of the host.

Actions: examine, modify.

=cut

omapi_attr ip_address => (
    isa => Ip,
    actions => [qw/examine modify/],
);

=head2 known

 $self->known($bool);
 $bool = $self->known;

=cut

omapi_attr known => (
    isa => 'Bool',
    actions => [qw/examine modify/],
);

=head2 name

 $self->name($str);
 $str = $self->name;

The name of the host declaration. This name must be unique among all
host declarations.

Actions: examine, lookup, modify.

=cut

omapi_attr name => (
    isa => 'Str',
    actions => [qw/examine lookup modify/],
);

=head2 statements

 $self->statements("foo,bar");
 $self->statements(\@statements);
 $str = $self->statements;

A list of statements in the format of the dhcpd.conf  file  that will
be executed whenever a message from the client is being processed.

Actions: modify

=cut

omapi_attr statements => (
    isa => Statements,
    actions => [qw/modify/],
);

=head1 ACKNOWLEDGEMENTS

Most of the documentation is taken from C<dhcpd(8)>.

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut
__PACKAGE__->meta->make_immutable;
1;
