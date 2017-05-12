package Net::Whois::Object::RouteSet::AFRINIC;

use base qw/Net::Whois::Object/;

# whois -t route-set -h whois.afrinic.net
# % This is the AfriNIC Whois server.
# 
# route-set:      [mandatory]  [single]     [primary/look-up key]
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

__PACKAGE__->attributes( 'primary', ['route_set'] );
__PACKAGE__->attributes( 'mandatory', [ 'route_set', 'descr', 'tech_c', 'admin_c', 'mnt_by', 'changed', 'source' ] );
__PACKAGE__->attributes( 'optional', [ 'members', 'mp_members', 'mbrs_by_ref', 'remarks', 'org', 'notify', 'mnt_lower' ] );
__PACKAGE__->attributes( 'single', [ 'route_set', 'source' ] );
__PACKAGE__->attributes( 'multiple', [ 'descr', 'members', 'mp_members', 'mbrs_by_ref', 'remarks', 'org', 'tech_c', 'admin_c', 'notify', 'mnt_by', 'mnt_lower', 'changed' ] );

=head1 NAME

Net::Whois::Object::RouteSet::AFRINIC - an object representation of the RPSL RouteSet block

=head1 DESCRIPTION

A route-set object defines a set of routes that can be represented by
route objects or by address prefixes. In the first case, the set is
populated by means of the "mbrs-by-ref:" attribute, in the latter, the
members of the set are explicitly listed in the "members:"
attribute. The "members:" attribute is a list of address prefixes or
other route-set names.  Note that the route-set class is a set of
route prefixes, not of database route objects.

=head1 METHODS

=head2 B<new( %options )>

Constructor for the Net::Whois::Object::RouteSet::AFRINIC class

=cut

sub new {
    my ( $class, @options ) = @_;

    my $self = bless {}, $class;
    $self->_init(@options);


    return $self;
}

=head2 B<route_set( [$route_set] )>

Accessor to the route_set attribute.
Accepts an optional route_set, always return the current route_set.

=head2 B<descr( [$descr] )>

Accessor to the descr attribute.
Accepts an optional descr line to be added to the descr array,
always return the current descr array.

=head2 B<members( [$members] )>

Accessor to the members attribute.
Accepts an optional members value to be added to the members array,
always return the current members array.

=head2 B<mbrs_by_ref( [$mbrs_by_ref] )>

Accessor to the mbrs_by_ref attribute.
Accepts an optional mbrs_by_ref to be added to the mbrs_by_ref array,
        always return the current 'mbrs_by_ref' array.

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

=head2 B<mnt_lower( [$mnt_lower] )>

Accessor to the mnt_lower attribute.
Accepts an optional mnt_lower value to be added to the mnt_lower array,
always return the current mnt_lower array.

=head2 B<mp_members( [$mp_member] )>

Accessor to the mp_members attribute.
Accepts an optional mp_member to be added to the mp_members array,
always return the current mp_members array.

=cut

1;
