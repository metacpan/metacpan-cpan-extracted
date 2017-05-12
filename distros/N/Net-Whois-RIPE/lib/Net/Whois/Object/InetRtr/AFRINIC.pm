package Net::Whois::Object::InetRtr::AFRINIC;

use base qw/Net::Whois::Object/;

# whois -t inet-rtr -h whois.afrinic.net
# % This is the AfriNIC Whois server.
# 
# inet-rtr:       [mandatory]  [single]     [primary/look-up key]
# descr:          [mandatory]  [multiple]   [ ]
# alias:          [optional]   [multiple]   [ ]
# local-as:       [mandatory]  [single]     [inverse key]
# ifaddr:         [mandatory]  [multiple]   [lookup key]
# interface:      [optional]   [multiple]   [lookup key]
# peer:           [optional]   [multiple]   [ ]
# mp-peer:        [optional]   [multiple]   [ ]
# member-of:      [optional]   [multiple]   [inverse key]
# remarks:        [optional]   [multiple]   [ ]
# org:            [optional]   [multiple]   [inverse key]
# admin-c:        [mandatory]  [multiple]   [inverse key]
# tech-c:         [mandatory]  [multiple]   [inverse key]
# notify:         [optional]   [multiple]   [inverse key]
# mnt-by:         [mandatory]  [multiple]   [inverse key]
# changed:        [mandatory]  [multiple]   [ ]
# source:         [mandatory]  [single]     [ ]

__PACKAGE__->attributes( 'primary', ['inet_rtr'] );
__PACKAGE__->attributes( 'mandatory', [ 'inet_rtr', 'descr', 'local_as', 'ifaddr', 'admin_c', 'tech_c', 'mnt_by', 'changed', 'source' ] );
__PACKAGE__->attributes( 'optional', [ 'alias', 'interface', 'peer', 'mp_peer', 'member_of', 'remarks', 'org', 'notify' ] );
__PACKAGE__->attributes( 'single', [ 'inet_rtr', 'local_as', 'source' ] );
__PACKAGE__->attributes( 'multiple', [ 'descr', 'alias', 'ifaddr', 'interface', 'peer', 'mp_peer', 'member_of', 'remarks', 'org', 'admin_c', 'tech_c', 'notify', 'mnt_by', 'changed' ] );


=head1 NAME

Net::Whois::Object::InetRtr::AFRINIC - an object representation of a RPSL InetRtr block

=head1 DESCRIPTION

The inet-rtr object specifies routers.

=head1 METHODS

=head2 new ( @options )

Constructor for the Net::Whois::Object::InetRtr::AFRINIC class

=cut

sub new {
    my ( $class, @options ) = @_;

    my $self = bless {}, $class;
    $self->_init(@options);

    return $self;
}

=head2 B<inet_rtr( [$inet_rtr] )>

Accessor to the inet_rtr attribute.
Accepts an optional inet_rtr, always return the current inet_rtr value.

The inet_rtr attribute is a valid DNS name for a router without a trailing
dot.

=head2 B<descr( [$descr] )>

Accessor to the descr attribute.
Accepts an optional descr value to be added to the descr array,
always return the current descr array.

A short description related to the object's purpose.

=head2 B<alias( [$alias] )>

Accessor to the alias attribute.
Accepts an optional alias to be added to the alias array,
always return the current alias array.

Each alias attribute, if present, is also standard DNS name for the
specified router.

=head2 B<local_as( [$local_as] )>

Accessor to the local_as attribute.
Accepts an optional local_as, always return the current local_as.

The local_as attribute specifies the AS Number of the AS that owns or
operates this router.

=head2 B<ifaddr( [$ifaddr] )>

Accessor to the ifaddr attribute.
Accepts an optional ifaddr value to be added to the ifaddr array,
always return the current ifaddr array.

The ifaddr attribute specifies the interface address within an Internet
router, as well as an optional action to set other parameters on this
interface.

=head2 B<peer( [$peer] )>

Accessor to the peer attribute.
Accepts an optional peer to be added to the peer array,
always return the current peer array.

The peer attribute specifies the details of any interior or exterior router
peering.

=head2 B<member_of( [$member_of] )>

Accessor to the member_of attribute.
Accepts an optional member_of value to be be added to the member_of array,
always return the current member_of array.

The member_of attribute value identifies a set object that this object
wants to be a member of. This claim, however, should be acknowledged by a
respective mbrs-by-ref attribute in the referenced object.

=head2 B<remarks( [$remark] )>

Accessor to the remarks attribute.
Accepts an optional remark to be added to the remarks array,
always return the current remarks array.

General remarks. May include a URL or instructions on where to send abuse
complaints.

=head2 B<admin_c( [$contact] )>

Accessor to the admin_c attribute.
Accepts an optional contact to be added to the admin_c array,
always return the current admin_c array.

The NIC-handle of an on-site contact Person object. As more than one person
often fulfills a role function, there may be more than one admin_c listed.

An administrative contact (admin_c) must be someone who is physically
located at the site of the network.

=head2 B<tech_c( [$contact] )>

Accessor to the tech_c attribute.
Accepts an optional contact to be added to the tech_c array,
always return the current tech_c array.

The NIC-handle of a technical contact Person or Role object.  As more than
one person often fulfills a role function, there may be more than one tech_c
listed.

A technical contact (tech_c) must be a person responsible for the
day-to-day operation of the network, but does not need to be
physically located at the site of the network.

=head2 B<notify( [$notify] )>

Accessor to the notify attribute.
Accepts an optional notify value to be added to the notify array,
always return the current notify array.

The email address to which notifications of changes to this object should
be sent.

=head2 B<mnt_by( [$mnt_by] )>

Accessor to the mnt_by attribute.
Accepts an optional mnt_by value to be added to the mnt_by array,
always return the current mnt_by array.

Lists a registered 'mntner' used to authorize and authenticate changes to this
object.

=head2 B<changed( [$changed] )>

Accessor to the changed attribute.
Accepts an optional changed value to be added to the changed array,
always return the current changed array.

The email address of who last updated the database object and the date it
occurred.

Every time a change is made to a database object, this attribute will show
the email address of the person who made those changes.
Please use the address format specified in RFC 822 - Standard for
the Format of ARPA Internet Text Message and provide the date
format using one of the following two formats: YYYYMMDD or YYMMDD.

=head2 B<source( [$source] )>

Accessor to the source attribute.
Accepts an optional source, always return the current source.

The database where the object is registered.

=head2 B<mp_peer( [$peer] )>

Accessor to the mp_peer attribute.
Accepts an optional peer to be added to the mp_peer array,
always return the current mp_peer array.

This attribute performs the same function as the peer attribute above. The
difference is that mp-peer allows both IPv4 and IPv6 address families to be
specified.

The mp-peer attribute extends the peer attribute for IPv6 addresses.

=head2 B<interface( [$interface] )>

Accessor to the interface attribute.
Accepts an optional interface to be added to the interface array,
always return the current interface array.

The interface attribute specifies a multi-protocol interface address within
an Internet router, optional action and tunnel definition.

=head2 B<org( [$org] )>

Accessor to the org attribute.
Accepts an optional org to be added to the org array,
always return the current org array.

The organisation entity this object is bound to.

=cut

1;
