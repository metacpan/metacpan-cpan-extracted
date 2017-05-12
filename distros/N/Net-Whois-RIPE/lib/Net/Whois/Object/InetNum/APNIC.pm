package Net::Whois::Object::InetNum::APNIC;

use base qw/Net::Whois::Object/;

# whois -h whois.apnic.net -t inetnum
# % [whois.apnic.net]
# % Whois data copyright terms    http://www.apnic.net/db/dbcopyright.html
# 
# inetnum:        [mandatory]  [single]     [primary/lookup key]
# netname:        [mandatory]  [single]     [lookup key]
# descr:          [mandatory]  [multiple]   [ ]
# country:        [mandatory]  [multiple]   [ ]
# geoloc:         [optional]   [single]     [ ]
# language:       [optional]   [multiple]   [ ]
# org:            [optional]   [single]     [inverse key]
# admin-c:        [mandatory]  [multiple]   [inverse key]
# tech-c:         [mandatory]  [multiple]   [inverse key]
# status:         [mandatory]  [single]     [ ]
# remarks:        [optional]   [multiple]   [ ]
# notify:         [optional]   [multiple]   [inverse key]
# mnt-by:         [mandatory]  [multiple]   [inverse key]
# mnt-lower:      [optional]   [multiple]   [inverse key]
# mnt-routes:     [optional]   [multiple]   [inverse key]
# mnt-irt:        [mandatory]  [multiple]   [inverse key]
# changed:        [mandatory]  [multiple]   [ ]
# source:         [mandatory]  [single]     [ ]
# 
# % This query was served by the APNIC Whois Service version 1.68.5 (WHOIS4)

__PACKAGE__->attributes( 'primary',   [ 'inetnum' ] );
__PACKAGE__->attributes( 'mandatory', [ 'inetnum', 'netname', 'descr', 'country', 'admin_c', 'tech_c', 'status', 'mnt_by', 'mnt_irt', 'changed', 'source' ] );
__PACKAGE__->attributes( 'optional',  [ 'geoloc', 'language', 'org', 'remarks', 'notify', 'mnt_lower', 'mnt_routes' ] );
__PACKAGE__->attributes( 'single',    [ 'inetnum', 'netname', 'geoloc', 'org', 'status', 'source' ] );
__PACKAGE__->attributes( 'multiple',  [ 'descr', 'country', 'language', 'admin_c', 'tech_c', 'remarks', 'notify', 'mnt_by', 'mnt_lower', 'mnt_routes', 'mnt_irt', 'changed' ] );

=head1 NAME

Net::Whois::Object::InetNum::APNIC - an object representation of a RPSL InetNum block

=head1 DESCRIPTION

An inetnum object contains information on allocations and assignments
of IPv4 address space.

=head1 METHODS

=head2 new ( @options )

Constructor for the Net::Whois::Object::InetNum::APNIC class

=cut

sub new {
    my ( $class, @options ) = @_;

    my $self = bless {}, $class;

    $self->_init(@options);

    return $self;
}

=head2 B<inetnum( [$inetnum] )>

Accessor to the inetnum attribute.
Accepts an optional inetnum value, always return the current inetnum value.

=head2 B<netname( [$netname] )>

Accessor to the netname attribute.
Accepts an optional netname, always return the current netname.

=head2 B<descr( [$descr] )>

Accessor to the descr attribute.
Accepts an optional descr value to be added to the descr array,
always return the current descr array.

=head2 B<country( [$country] )>

Accessor to the country attribute.
Accepts an optional country to be added to the country array,
always return the current country array.

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

Accessor to the 'org' attribute.
Accepts an optional org, always return the current org.

Only a single value for the org attribute is allowed in the Inetnum object.
This is to ensure only one organisation is responsible for this resource.

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

=head2 B<status( [$status] )>

Accessor to the 'status' attribute.
Accepts an optional status, always return the current status.

The status attribute indicates where the address range represented by an
inetnum object sits in a hierarchy and how it is used.

Status can have one of these values:

=over 4

=item ALLOCATED UNSPECIFIED

=item ALLOCATED PA

=item ALLOCATED PI

=item LIR-PARTITIONED PA

=item LIR-PARTITIONED PI

=item SUB-ALLOCATED PA

=item ASSIGNED PA

=item ASSIGNED PI

=item ASSIGNED ANYCAST

=item EARLY-REGISTRATION

=item NOT-SET

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

Lists a registered Mntner used to authorize and authenticate changes to this
object.

=head2 B<mnt_lower( [$mnt_lower] )>

Accessor to the mnt_lower attribute.
Accepts an optional mnt_lower value to be added to the mnt_lower array,
always return the current mnt_lower array.

Sometimes there is a hierarchy of maintainers. In these cases, mnt_lower is
used as well as mnt_by.

=head2 B<mnt_routes( [$mnt_route] )>

Accessor to the mnt_routes attribute.
Accepts an optional mnt_route to be added to the mnt_routes array,
always return the current mnt_routes array.

The identifier of a registered Mntner object used to control the creation of
Route objects associated with the address range specified by the Inetnum
object.

=head2 B<mnt_domains( [$mnt_domain] )>

Accessor to the mnt_domains attribute.
Accepts an optional mnt_domain to be added to the mnt_domains array,
always return the current mnt_domains array.

The identifier of a registered Mntner object used to control the creation of
Domain objects associated with the address range specified by the Inetnum
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

=head2 B<mnt_irt( [$mnt_irt] )>

Accessor to the mnt_irt attribute.
Accepts an optional mnt_irt value to be added to the mnt_irt array,
always return the current mnt_irt array.

The identifier of a registered Mntner object used to provide information
about a Computer Security Incident Response Team (CSIRT).

=cut

1;
