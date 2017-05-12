package Net::Whois::Object::Inet6Num::AFRINIC;

use base qw/Net::Whois::Object/;

# whois -t inet6num -h whois.afrinic.net
# % This is the AfriNIC Whois server.
# 
# inet6num:       [mandatory]  [single]     [primary/look-up key]
# netname:        [mandatory]  [single]     [lookup key]
# descr:          [mandatory]  [multiple]   [ ]
# country:        [mandatory]  [multiple]   [ ]
# org:            [optional]   [single]     [inverse key]
# admin-c:        [mandatory]  [multiple]   [inverse key]
# tech-c:         [mandatory]  [multiple]   [inverse key]
# status:         [mandatory]  [single]     [ ]
# remarks:        [optional]   [multiple]   [ ]
# notify:         [optional]   [multiple]   [inverse key]
# mnt-by:         [mandatory]  [multiple]   [inverse key]
# mnt-lower:      [optional]   [multiple]   [inverse key]
# mnt-routes:     [optional]   [multiple]   [inverse key]
# mnt-domains:    [optional]   [multiple]   [inverse key]
# mnt-irt:        [optional]   [multiple]   [inverse key]
# changed:        [mandatory]  [multiple]   [ ]
# source:         [mandatory]  [single]     [ ]
# parent:         [generated]  [multiple]   [ ]

__PACKAGE__->attributes( 'primary',   ['inet6num'] );
__PACKAGE__->attributes( 'mandatory', [ 'inet6num', 'netname', 'descr', 'country', 'admin_c', 'tech_c', 'status', 'mnt_by', 'changed', 'source' ] );
__PACKAGE__->attributes( 'optional', ['org', 'remarks', 'notify', 'mnt_lower', 'mnt_routes', 'mnt_domains', 'mnt_irt' ] );
__PACKAGE__->attributes( 'single', [ 'inet6num', 'netname', 'org', 'status', 'source' ] );
__PACKAGE__->attributes( 'multiple', [ 'descr', 'country', 'admin_c', 'tech_c', 'remarks', 'notify', 'mnt_by', 'mnt_lower', 'mnt_routes', 'mnt_domains', 'mnt_irt', 'changed' ] );

=head1 NAME

Net::Whois::Object::Inet6Num::AFRINIC - an object representation of a RPSL Inet6Num block

=head1 DESCRIPTION

An inet6num object contains information on allocations and assignments
of IPv6 address space.

=head1 METHODS

=head2 new ( @options )

Constructor for the Net::Whois::Object::Inet6Num::AFRINIC class

=cut

sub new {
    my ( $class, @options ) = @_;

    my $self = bless {}, $class;
    $self->_init(@options);

    return $self;
}

=head2 B<inet6num( [$inet6num] )>

Accessor to the inet6num attribute.
Accepts an optional inet6num value, always return the current inet6num value.

The inet6num attribute specifies a range of IPv6 addresses that the
inet6num object presents. The range may be a single address.

Addresses can only be expressed in prefix notation

=head2 B<netname( [$netname] )>

Accessor to the netname attribute.
Accepts an optional netname, always return the current netname.

The netname attribute is the name of a range of IP address space. It is
recommended that the same netname is used for any set of assignment ranges
used for a common purpose.

=head2 B<descr( [$descr] )>

Accessor to the descr attribute.
Accepts an optional descr to be added to the descr array,
always return the current descr array.

Description of the organization allocated or assigned the address space shown
in the inet6num.

=head2 B<country( [$country] )>

Accessor to the country attribute.
Accepts an optional country to be added to the country array,
always return the current country array.

The country attribute identifies the country. It has never been specified
if this is the country where the addresses are used, where the issuing
organisation is based or some transit country in between. There are no rules
defined for this attribute. It cannot therefore be used in any reliable way to
map IP addresses to countries.

=head2 B<geoloc( [$geoloc] )>

Accessor to the geoloc attribute.
Accepts an optional geoloc, always return the current geoloc.

The location coordinates for the resource

Location coordinates of the resource. Can take one of the following forms:
[-90,90][-180,180]

=head2 B<language( [$language] )>

Accessor to the language attribute.
Accepts an optional language to be added to the language array,
always return the current language array.

Identifies the language.

Valid two-letter ISO 639-1 language code.

=head2 B<org( [$org] )>

Accessor to the org attribute.
Accepts an optional org, always return the current org.

Only a single value for the org attribute is allowed in the inet6num
object. This is to ensure only one organisation is responsible for this
resource.

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

=head2 B<status( [$status] )>

Accessor to the status attribute.
Accepts an optional status, always return the current status.

The status attribute indicates where the address range represented by an
inet6num object sits in a hierarchy and how it is used.

Status can have one of these values:

=over 4

=item ALLOCATED-BY-RIR

=item ALLOCATED-BY-LIR

=item ASSIGNED

=item ASSIGNED ANYCAST

=item ASSIGNED PI

=back

=head2 B<remarks( [$remark] )>

Accessor to the remarks attribute.
Accepts an optional remark to be added to the remarks array,
always return the current remarks array.

General remarks. May include a URL or instructions on where to send abuse
complaints.

=head2 B<notify( [$notify] )>

Accessor to the notify attribute.
Accepts an optional notify value to be added to the notify array,
always return the current notify array.

The email address to which notifications of changes to this object should be
sent.

=head2 B<mnt_by( [$mnt_by] )>

Accessor to the mnt_by attribute.
Accepts an optional mnt_by value to be added to the mnt_by array,
always return the current mnt_by array.

=head2 B<mnt_lower( [$mnt_lower] )>

Accessor to the mnt_lower attribute.
Accepts an optional mnt_lower value to be added to the mnt_lower array,
always return the current mnt_lower array.

Sometimes there is a hierarchy of maintainers. In these cases, mnt-lower is
used as well as 'mnt-by.'

=head2 B<mnt_routes( [$mnt_route] )>

Accessor to the mnt_routes attribute.
Accepts an optional mnt_route to be added to the mnt_routes array,
always return the current mnt_routes array.

The identifier of a registered Mntner object used to control the creation of
Route6 objects associated with the address range specified by the Inet6num
object.

=head2 B<mnt_domains( [$mnt_route] )>

Accessor to the mnt_domains attribute.
Accepts an optional mnt_route to be added to the mnt_domains array,
always return the current mnt_domains array.

The identifier of a registered Mntner object used to control the creation of
Domain objects associated with the address range specified by the Inet6num
object.

=head2 B<mnt_irt( [$mnt_irt] )>

Accessor to the mnt_irt attribute.
Accepts an optional mnt_irt to be added to the mnt_irt array,
always return the current mnt_irt array.

mnt_irt references an Irt object. Authorisation is required from the Irt
object to be able to add this reference.

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

=cut

1;
