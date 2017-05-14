package Net::Whois::Object::Route;

use base qw/Net::Whois::Object/;

# http://www.ripe.net/data-tools/support/documentation/update-ref-manual#section-25
# http://www.apnic.net/apnic-info/whois_search/using-whois/guide/route
#
# From: whois -t route
# % This is the RIPE Database query service.
# % The objects are in RPSL format.
# %
# % The RIPE Database is subject to Terms and Conditions.
# % See http://www.ripe.net/db/support/db-terms-conditions.pdf
# 
# route:          [mandatory]  [single]     [primary/lookup key]
# descr:          [mandatory]  [multiple]   [ ]
# origin:         [mandatory]  [single]     [primary/inverse key]
# pingable:       [optional]   [multiple]   [ ]
# ping-hdl:       [optional]   [multiple]   [inverse key]
# holes:          [optional]   [multiple]   [ ]
# org:            [optional]   [multiple]   [inverse key]
# member-of:      [optional]   [multiple]   [inverse key]
# inject:         [optional]   [multiple]   [ ]
# aggr-mtd:       [optional]   [single]     [ ]
# aggr-bndry:     [optional]   [single]     [ ]
# export-comps:   [optional]   [single]     [ ]
# components:     [optional]   [single]     [ ]
# remarks:        [optional]   [multiple]   [ ]
# notify:         [optional]   [multiple]   [inverse key]
# mnt-lower:      [optional]   [multiple]   [inverse key]
# mnt-routes:     [optional]   [multiple]   [inverse key]
# mnt-by:         [mandatory]  [multiple]   [inverse key]
# changed:        [mandatory]  [multiple]   [ ]
# source:         [mandatory]  [single]     [ ]
#
# % This query was served by the RIPE Database Query Service version 1.38 (WHOIS4)


__PACKAGE__->attributes( 'primary',   ['route'] );
__PACKAGE__->attributes( 'mandatory', [ 'route', 'origin', 'descr', 'mnt_by', 'changed', 'source' ] );
__PACKAGE__->attributes( 'optional', [ 'pingable', 'ping_hdl', 'holes', 'org', 'member_of', 'inject', 'aggr_mtd', 'aggr_bndry', 'export_comps', 'components', 'remarks', 'cross_mnt', 'cross_nfy', 'notify', 'mnt_lower', 'mnt_routes', 'country' ] );
__PACKAGE__->attributes( 'single', [ 'route', 'origin', 'aggr_mtd', 'aggr_bndry', 'export_comps', 'components', 'source', 'country' ] );
__PACKAGE__->attributes( 'multiple', [ 'descr', 'mnt_by', 'changed','pingable', 'ping_hdl', 'holes', 'org', 'member_of', 'inject', 'remarks', 'cross_mnt', 'cross_nfy', 'notify', 'mnt_lower', 'mnt_routes' ] );

=head1 NAME

Net::Whois::Object::Route - an object representation of the RPSL Route block

=head1 DESCRIPTION

Route objects are used to help configure your network's routers. Route objects, 
in combination with the aut-num and other related objects, can be used to
describe your IPv4 routing policy in a compact form. This can help your
network identify routing policy errors and omissions more easily than by
reading long configuration files.


=head1 METHODS

=head2 B<new( %options )>

Constructor for the Net::Whois::Object::Route class

=cut

sub new {
    my ( $class, @options ) = @_;

    my $self = bless {}, $class;
    $self->_init(@options);


    return $self;
}

=head2 B<route( [$route] )>

Accessor to the route attribute.
Accepts an optional route, always return the current route.

=head2 B<descr( [$descr] )>

Accessor to the descr attribute.
Accepts an optional descr line to be added to the descr array,
always return the current descr array.

=head2 B<origin( [$origin] )>

Accessor to the origin attribute.
Accepts an optional origin, always return the current origin.

=head2 B<pingable( [$pingable] )>

Accessor to the pingable attribute.
Accepts an optional pingable line to be added to the pingable array,
always return the current pingable array.

An IPv4 or an IPv6 address allowing a network operator to advertise an IP address of a node
that should be reachable from outside networks. This node can be
used as a destination address for diagnostic tests.
The IP address must be within the address range of the prefix
containing this attribute.

=head2 B<ping_hdl( [$ping_hdl] )>

Accessor to the ping_hdl attribute.
Accepts an optional ping_hdl line to be added to the ping_hdl array,
always return the current ping_hdl array.

References a person or role capable of responding to queries
concerning the IP address(es) specified in the 'pingable'
attribute.

=head2 B<holes( [$hole] )>

Accessor to the holes attribute.
Accepts an optional hole to be added to the holes array,
always return the current holes array.

=head2 B<org( [$org] )>

Accessor to the org attribute.
Accepts an optional org, always return the current org.

Points to an existing organisation object representing the entity that
holds the resource.

The 'ORG-' string followed by 2 to 4 characters, followed by up to 5 digits
followed by a source specification.  The first digit must not be "0".
Source specification starts with "-" followed by source name up to
9-character length.

=head2 B<member_of( [$member_of] )>

Accessor to the member_of attribute.
Accepts an optional member_of value to be added to the member_of array,
always return the current member_of array.

=head2 B<inject( [$inject] )>

Accessor to the inject attribute.
Accepts an optional inject value to be added to the inject array,
always return the current inject array.

=head2 B<aggr_mtd( [$aggr_mtd] )>

Accessor to the aggr_mtd attribute.
Accepts an optional aggr_mtd value to be added to the aggr_mtd array,
always return the current aggr_mtd.

=head2 B<aggr_bndry( [$aggr_bndry] )>

Accessor to the aggr_bndry attribute.
Accepts an optional aggr_bndry value to be added to the aggr_bndry array,
always return the current aggr_bndry.

=head2 B<export_comps( [$export_comp] )>

Accessor to the export_comps attribute.
Accepts an optional export_comp value to be added the export_comps array,
always return the current export_comps.

=head2 B<components( [$component] )>

Accessor to the components attribute.
Accepts an optional component to be added to the components array,
always return the current components.

=head2 B<remarks( [$remark] )>

Accessor to the remarks attribute.
Accepts an optional remark to be added to the remarks array,
always return the current 'remarks' array.

=head2 B<cross_mnt( [$cross_mnt] )>

Accessor to the cross_mnt attribute.
Accepts an optional cross_mnt value to be added to the cross_mnt array,
always return the current cross_mnt array.

=head2 B<cross_nfy( [$cross_nfy] )>

Accessor to the cross_nfy attribute.
Accepts an optional cross_nfy value to be added to the cross_nfy array,
always return the current cross_nfy array.

=head2 B<notify( [$notify] )>

Accessor to the notify attribute.
Accepts an optional notify value to be added to the notify array,
always return the current notify array.

=head2 B<mnt_lower( [$mnt_lower] )>

Accessor to the mnt_lower attribute.
Accepts an optional mnt_lower value to be added to the mnt_lower array,
always return the current mnt_lower array.

=head2 B<mnt_routes( [$mnt_route] )>

Accessor to the mnt_routes attribute.
Accepts an optional mnt_route to be added to the mnt_routes array,
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

=head2 B<country( [$country] )>

Accessor to the country attribute.
Accepts an optional country, always return the current country.
Two letter ISO 3166 code of the country or economy where the admin-c is based.

Please use UPPERCASE letters.

=cut

1;
