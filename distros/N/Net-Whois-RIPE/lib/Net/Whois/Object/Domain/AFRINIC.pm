package Net::Whois::Object::Domain::AFRINIC;

use base qw/Net::Whois::Object/;

# whois -t domain -h whois.afrinic.net
# % This is the AfriNIC Whois server.
# 
# domain:         [mandatory]  [single]     [primary/look-up key]
# descr:          [mandatory]  [multiple]   [ ]
# org:            [optional]   [multiple]   [inverse key]
# admin-c:        [mandatory]  [multiple]   [inverse key]
# tech-c:         [mandatory]  [multiple]   [inverse key]
# zone-c:         [mandatory]  [multiple]   [inverse key]
# nserver:        [optional]   [multiple]   [inverse key]
# ds-rdata:       [optional]   [multiple]   [inverse key]
# sub-dom:        [optional]   [multiple]   [inverse key]
# dom-net:        [optional]   [multiple]   [ ]
# remarks:        [optional]   [multiple]   [ ]
# notify:         [optional]   [multiple]   [inverse key]
# mnt-by:         [optional]   [multiple]   [inverse key]
# mnt-lower:      [optional]   [multiple]   [inverse key]
# refer:          [optional]   [single]     [ ]
# changed:        [mandatory]  [multiple]   [ ]
# source:         [mandatory]  [single]     [ ]
    
__PACKAGE__->attributes( 'primary',   ['domain'] );
__PACKAGE__->attributes( 'mandatory', [ 'domain', 'descr', 'admin_c', 'tech_c', 'zone_c', 'changed', 'source' ] );
__PACKAGE__->attributes( 'optional', [ 'org', 'nserver', 'ds_rdata', 'sub_dom', 'dom_net', 'remarks', 'notify', 'mnt_by', 'mnt_lower', 'refer' ] );
__PACKAGE__->attributes( 'single', [ 'domain', 'refer', 'source' ] );
__PACKAGE__->attributes( 'multiple', [ 'descr', 'org', 'admin_c', 'tech_c', 'zone_c', 'nserver', 'ds_rdata', 'sub_dom', 'dom_net', 'remarks', 'notify', 'mnt_by', 'mnt_lower', 'changed' ] );


=head1 NAME

Net::Whois::Object::Domain::AFRINIC - an object representation of a RPSL Domain block

=head1 DESCRIPTION

The domain object represents Top Level Domain (TLD) and other domain
registrations.  It is also used for Reverse Delegations.  The domain
name is written in fully qualified format, without a trailing " . "

=head1 METHODS

=head2 new ( @options )

Constructor for the Net::Whois::Object::Domain::AFRINIC class

=cut

sub new {
    my ( $class, @options ) = @_;

    my $self = bless {}, $class;
    $self->_init(@options);

    return $self;
}

=head2 B<domain( [$domain] )>

Accessor to the domain attribute.
Accepts an optional domain, always return the current domain.

The domain name in fully qualified format, without a trailing dot. If a
trailing dot is included it will be removed.

=cut

sub domain {
    my ( $self, $domain ) = @_;

    # Enforce the format
    $domain =~ s/\.$// if $domain;

    return $self->_single_attribute_setget( 'domain', $domain );
}

=head2 B<descr( [$descr] )>

Accessor to the descr attribute.
Accepts an optional descr line to be added to the descr array,
always return the current descr array.

The name of the organization responsible for the reverse delegation. Or can
describe the use of the IP range described in the domain object.

=head2 B<org( [$org] )>

Accessor to the org attribute.
Accepts an optional org value to be added to the org array,
always return the current org array.

The organisation responsible for this domain.

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

=head2 B<zone_c( [$contact] )>

Accessor to the zone_c attribute.
Accepts an optional contact to be added to the zone_c array,
always return the current zone_c array.

The NIC-handle of a 'person' or 'role' object with authority over a zone.

=head2 B<nserver( [$server] )>

Accessor to the nserver attribute.
Accepts an optional server to be added to the nserver array,
always return the current nserver array.

A list of nameservers for a domain object. A minimum of one nameserver is
mandatory.

=head2 B<ds_rdata( [$server] )>

Accessor to the ds_rdata attribute.
Accepts an optional server to be added to the ds_rdata array,
always return the current ds_rdata array.

The ds_rdata attribute holds information about a signed delegation record
for DNSSEC (short for DNS Security Extensions)

=head2 B<sub_dom( [$dom] )>

Accessor to the sub_dom attribute.
Accepts an optional dom to be added to the sub_dom array,
always return the current sub_dom array.

The sub_dom attribute specifies a list of sub-domains of a domain. Domain
names are relative to the domain represented by the domain object that
contains this attribute

=head2 B<dom_net( [$dom_net] )>

Accessor to the dom_net attribute.
Accepts an optional dom_net value to be added to the dom_net array,
always return the current dom_net array.

The dom_net attribute contains a list of IP networks in a domain.

=head2 B<remarks( [$remark] )>

Accessor to the remarks attribute.
Accepts an optional remark to be added to the remarks array,
always return the current remarks array.

General remarks. May include a URL or email address.

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

Lists a registered 'mntner' used to authorize and authenticate changes to
this object.

=head2 B<mnt_lower( [$mnt_lower] )>

Accessor to the mnt_lower attribute.
Accepts an optional mnt_lower value to be added to the mnt_lower array,
always return the current mnt_lower array.

The identifier of a registered mntner object used to authorize the creation of
reverse domain objects more specific than the reverse domain specified by this
object.

=head2 B<refer( [$refer] )>

Accessor to the refer attribute.
Accepts an optional refer, always return the current refer.

The refer attribute is used to refer a query to another authorative
database. See the "RIPE Database Query Reference Manual" for an
explanation of its use. This will be redundant when forward domains are
removed and may be deprecated.

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
