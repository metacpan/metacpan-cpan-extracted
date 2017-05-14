package Net::Whois::Object::RtrSet;

use base qw/Net::Whois::Object/;

# http://www.ripe.net/data-tools/support/documentation/update-ref-manual#section-27
# http://www.apnic.net/apnic-info/whois_search/using-whois/guide/rtr-set
#
# From: whois -t route-set
# % This is the RIPE Database query service.
# % The objects are in RPSL format.
# %
# % The RIPE Database is subject to Terms and Conditions.
# % See http://www.ripe.net/db/support/db-terms-conditions.pdf
# 
# route-set:      [mandatory]  [single]     [primary/lookup key]
# descr:          [mandatory]  [multiple]   [ ]
# members:        [optional]   [multiple]   [ ]
# mp-members:     [optional]   [multiple]   [ ]
# mbrs-by-ref:    [optional]   [multiple]   [inverse key]
# remarks:        [optional]   [multiple]   [ ]
# org:            [optional]   [multiple]   [inverse key]
# tech-c:         [mandatory]  [multiple]   [inverse key]
# admin-c:        [mandatory]  [multiple]   [inverse key]
# notify:         [optional]   [multiple]   [inverse key]
# mnt-by:         [mandatory]  [multiple]   [inverse key]
# mnt-lower:      [optional]   [multiple]   [inverse key]
# changed:        [mandatory]  [multiple]   [ ]
# source:         [mandatory]  [single]     [ ]
#
# % This query was served by the RIPE Database Query Service version 1.38 (WHOIS2)


__PACKAGE__->attributes( 'primary', ['rtr_set'] );
__PACKAGE__->attributes( 'mandatory', [ 'rtr_set', 'descr', 'tech_c', 'admin_c', 'mnt_by', 'changed', 'source' ] );
__PACKAGE__->attributes( 'optional', [ 'members', 'mbrs_by_ref', 'remarks', 'org', 'notify', 'mp_members' ] );
__PACKAGE__->attributes( 'single', [ 'rtr_set', 'source' ] );
__PACKAGE__->attributes( 'multiple', [ 'descr', 'tech_c', 'admin_c', 'mnt_by', 'changed', 'members', 'mbrs_by_ref', 'remarks', 'org', 'notify', 'mp_members' ] );

=head1 NAME

Net::Whois::Object::RtrSet - an object representation of the RPSL RtrSet block

=head1 DESCRIPTION

A rtr-set object defines a set of routers. A set may be described by
the "members:" attribute, which is a list of inet-rtr names, IPv4
addresses or other rtr-set names. A set may also be populated by means
of the "mbrs-by-ref:" attribute, in which case it is represented by
inet-rtr objects.

=head1 METHODS

=head2 B<new( %options )>

Constructor for the Net::Whois::Object::RtrSet class

=cut

sub new {
    my ( $class, @options ) = @_;

    my $self = bless {}, $class;
    $self->_init(@options);

    return $self;
}

=head2 B<rtr_set( [$rtr_set] )>

Accessor to the rtr_set attribute.
Accepts an optional rtr_set, always return the current rtr_set.

=head2 B<descr( [$descr] )>

Accessor to the descr attribute.
Accepts an optional descr line to be added to the descr array,
always return the current descr array.

=head2 B<members( [$member] )>

Accessor to the members attribute.
Accepts an optional member to be added to the members array,
always return the current members array.

=head2 B<mbrs_by_ref( [$mbrs_by_ref] )>

Accessor to the mbrs_by_ref attribute.
Accepts an optional mbrs_by_ref value to be added to the mbrs_by_ref array,
always return the current mbrs_by_ref array.

=head2 B<remarks( [$remark] )>

Accessor to the remarks attribute.
Accepts an optional remark to be added to the remarks array,
always return the current remarks array.

=head2 B<org( [$org] )>

Accessor to the org attribute.
Accepts an optional org, always return the current org.

Points to an existing organisation object representing the entity that
holds the resource.

The 'ORG-' string followed by 2 to 4 characters, followed by up to 5 digits
followed by a source specification.  The first digit must not be "0".
Source specification starts with "-" followed by source name up to
9-character length.

=head2 B<tech_c( [$contact] )>

Accessor to the tech_c attribute.
Accepts an optional contact to be added to the tech_c array,
always return the current tech_c array.

=head2 B<admin_c( [$contact] )>

Accessor to the admin_c attribute.
Accepts an optional contact to be added to the admin_c array,
always return the current admin_c array.

=head2 B<notify( [$notify] )>

Accessor to the notify attribute.
Accepts an optional notify value to be added to the notify array,
always return the current notify array.

=head2 B<mnt_by( [$mnt_by])>

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

=head2 B<mp_members( [$mp_member] )>

Accessor to the mp_members attribute.
Accepts an optional mp_member to be added to the mp_members array,
always return the current mp_members array.

This attribute performs the same function as the members attribute above.
The difference is that mp-members allows both IPv4 and IPv6 address families
to be specified.

Explicitly lists IPv4 or IPv6 'members' of the rtr-set can be:

    * inet-rtr objects
    * other rtr-set objects
    * ipv4 address
    * ipv6 address

=cut

1;
