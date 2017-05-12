package Net::Whois::Object::AutNum::APNIC;

use base qw/Net::Whois::Object/;

# whois -h whois.apnic.net -t aut-num
# % [whois.apnic.net]
# % Whois data copyright terms    http://www.apnic.net/db/dbcopyright.html
# 
# aut-num:        [mandatory]  [single]     [primary/lookup key]
# as-name:        [mandatory]  [single]     [ ]
# descr:          [mandatory]  [multiple]   [ ]
# country:        [mandatory]  [single]     [ ]
# member-of:      [optional]   [multiple]   [inverse key]
# import:         [optional]   [multiple]   [ ]
# mp-import:      [optional]   [multiple]   [ ]
# export:         [optional]   [multiple]   [ ]
# mp-export:      [optional]   [multiple]   [ ]
# default:        [optional]   [multiple]   [ ]
# mp-default:     [optional]   [multiple]   [ ]
# remarks:        [optional]   [multiple]   [ ]
# org:            [optional]   [single]     [inverse key]
# admin-c:        [mandatory]  [multiple]   [inverse key]
# tech-c:         [mandatory]  [multiple]   [inverse key]
# notify:         [optional]   [multiple]   [inverse key]
# mnt-lower:      [optional]   [multiple]   [inverse key]
# mnt-routes:     [optional]   [multiple]   [inverse key]
# mnt-by:         [mandatory]  [multiple]   [inverse key]
# mnt-irt:        [mandatory]  [multiple]   [inverse key]
# changed:        [mandatory]  [multiple]   [ ]
# source:         [mandatory]  [single]     [ ]
# 
# % This query was served by the APNIC Whois Service version 1.68.5 (WHOIS4)


__PACKAGE__->attributes( 'primary',   ['aut_num'] );
__PACKAGE__->attributes( 'mandatory', [ 'aut_num', 'as_name', 'descr', 'country', 'admin_c', 'tech_c', 'mnt_by', 'mnt_irt', 'changed', 'source' ] );
__PACKAGE__->attributes( 'optional', [ 'member_of', 'import', 'mp_import', 'export', 'mp_export', 'default', 'mp_default', 'remarks', 'org', 'notify', 'mnt_lower', 'mnt_routes'  ] );
__PACKAGE__->attributes( 'single', [ 'aut_num', 'as_name', 'country', 'org', 'source' ] );
__PACKAGE__->attributes( 'multiple', [ 'descr', 'member_of', 'import', 'mp_import', 'export', 'mp_export', 'default', 'mp_default', 'remarks', 'admin_c', 'tech_c', 'notify', 'mnt_lower', 'mnt_routes', 'mnt_by', 'mnt_irt', 'changed' ] );


=head1 NAME

Net::Whois::Object::AutNum::APNIC - an object representation of a RPSL AutNum block

=head1 DESCRIPTION

Autonomous System numbers ('aut-num' objects) are globally unique identifiers
for Autonomous Systems.

The aut-num object specifies routing policies. It refers to a group of IP
networks that have a single and clearly defined external routing policy,
operated by one or more network operators – an Autonomous System (AS).

=head1 METHODS

=head2 new ( @options )

Constructor for the Net::Whois::Object::AutNum::APNIC class

=cut

sub new {
    my ( $class, @options ) = @_;

    my $self = bless {}, $class;
    $self->_init(@options);

    return $self;
}

=head2 B<aut_num( [$aut_num] )>

Accessor to the aut_num attribute.
Accepts an optional aut_num, always return the current aut_num array.

The value of the aut_num attribute is the AS Number of the Autonomous
System that this object describes and takes the form of ASn where n is 
a 32 bit number..

Leading zeroes (AS0352) are not allowed and will be removed (AS352) by the
database software.

=cut

sub aut_num {
    my ( $self, $aut_num ) = @_;

    if ( $aut_num and $aut_num !~ /^AS\d+/ ) {
        warn "Illegal aut-num ($aut_num) : should be ASn, n being a 32 bit number with no leading 0";
    }

    return $self->_single_attribute_setget( 'aut_num', $aut_num );
}

=head2 B<as_name( [$as_name] )>

Accessor to the as_name attribute.
Accepts an optional as_name, always return the current as_name array.

The as-name attribute is a symbolic name of the AS.

=head2 B<descr( [$descr] )>

Accessor to the descr attribute.
Accepts an optional descr value to be added to the descr array, always return the current descr array.

=head2 B<member_of( [$mbr_of] )>

Accessor to the member_of attribute.
Accepts an optional member_of value to be added to the member_of array,
always return the current member_of array.

The member_of attribute value identifies a set object that this object
wants to be a member of. This claim, however, should be acknowledged by a
respective mbrs_by_ref attribute in the referenced object.

An aut-num may be useful to include in an 'as-set' if your network maintains a
number of Autonomous Systems or wishes to include its routes in an upstream
provider's routing information.

To be included in an 'as-set', the 'as-set' object must:
include the keyword "ANY" or the AS number's mbrs_by_ref attribute
and/or list the AS number in the members attribute

=head2 B<import( [$import] )>

Accessor to the import attribute.
Accepts an optional import line to be added to the import array,
always return the current import array.

The inbound IPv4 routing policy of the AS.

=head2 B<mp_import( [$import] )>

Accessor to the mp_import attribute.
Accepts an optional mp_import line to be added to the import array,
always return the current mp_import array.

The inbound IPv6 routing policy of the AS.

=head2 B<export( [$export] )>

Accessor to the export attribute.
Accepts an optional export line to be added to the export array,
always return the current export array.

The outbound routing policy of the AS.

=head2 B<mp_export( [$mp_export] )>

Accessor to the mp_export attribute.
Accepts an optional mp_export line to be added to the mp_export array,
always return the current mp_export array.

The outbound IPv6 routing policy of the AS.

=head2 B<default( [$default] )>

Accessor to the default attribute.
Accepts an optional default value to be added to the default array,
always return the current default array.

The peer network the AS will use for as a default, that is, when the AS has no
more-specific information on where to send the traffic.

=head2 B<mp_default( [$mp_default] )>

Accessor to the mp_default attribute.
Accepts an optional mp_default line to be added to the mp_default array,
always return the current mp_default array.

This attribute performs the same function as the 'default' attribute above.
The difference is that mp-default allows both IPv4 and IPv6 addresses to be
specified.

=head2 B<remarks( [$remark] )>

Accessor to the remarks attribute.
Accepts an optional remark to be added to the remarks array,
always return the current remarks array.

Information about the object that cannot be stated in other attributes. May
include a URL or email address.

=cut

=head2 B<admin_c( [$contact] )>

Accessor to the admin_c attribute.
Accepts an optional contact to be added to the admin_c array,
always return the current admin_c array.

The NIC-handle of an on-site contact 'person' object. As more than one person
often fulfills a role function, there may be more than one admin_c listed.

An administrative contact (admin_c) must be someone who is physically
located at the site of the network.

=head2 B<tech_c( [$contact] )>

Accessor to the tech_c attribute.
Accepts an optional contact to be added to the tech_c array,
always return the current tech_c array.

The NIC-handle of a technical contact 'person' or 'role' object.  As more than
one person often fulfills a role function, there may be more than one tech_c
listed.

A technical contact (tech_c) must be a person responsible for the
day-to-day operation of the network, but does not need to be
physically located at the site of the network.

=head2 B<notify( [$notify] )>

Accessor to the notify attribute.
Accepts an optional notify value to be added to the notify array,
always return the current notify array.

=cut

=head2 B<mnt_lower( [$mnt_lower] )>

Accessor to the mnt_lower attribute.
Accepts an optional mnt_lower value to be added to the mnt_lower array,
always return the current mnt_lower array.

=head2 B<mnt_routes( [$mnt_routes] )>

Accessor to the mnt_routes attribute.
Accepts an optional mnt_routes value to be added to the mnt_routes array,
always return the current mnt_routes array.

=head2 B<mnt_by( [$mnt_by] )>

Accessor to the mnt_by attribute.
Accepts an optional mnt_by value to be added to the mnt_by array,
always return the current mnt_by array.

=head2 B<changed( [$changed] )>

Accessor to the changed attribute.
Accepts an optional changed value to be added to the changed array,
always return the current changed array.

=head2 B<source( [$source] )>

Accessor to the source attribute.
Accepts an optional source, always return the current source.

The database where the object is registered.

=head2 B<org( [$org] )>

Accessor to the org attribute.
Accepts an optional org, always return the current org.

Only a single value for the org attribute is allowed in the aut-num object.
This is to ensure only one organisation is responsible for this resource.

=cut

1;
