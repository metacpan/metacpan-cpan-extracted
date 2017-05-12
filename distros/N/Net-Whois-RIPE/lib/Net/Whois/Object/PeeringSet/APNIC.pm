package Net::Whois::Object::PeeringSet::APNIC;

use base qw/Net::Whois::Object/;

# whois -h whois.apnic.net -t peering-set
# % [whois.apnic.net]
# % Whois data copyright terms    http://www.apnic.net/db/dbcopyright.html
# 
# peering-set:    [mandatory]  [single]     [primary/lookup key]
# descr:          [mandatory]  [multiple]   [ ]
# peering:        [optional]   [multiple]   [ ]
# mp-peering:     [optional]   [multiple]   [ ]
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
# % This query was served by the APNIC Whois Service version 1.68.5 (WHOIS1)


__PACKAGE__->attributes( 'primary',   [ 'peering_set' ] );
__PACKAGE__->attributes( 'mandatory', [ 'peering_set', 'descr', 'tech_c', 'admin_c', 'mnt_by', 'changed', 'source' ] );
__PACKAGE__->attributes( 'optional',  [ 'peering', 'mp_peering', 'remarks', 'org', 'notify', 'mnt_lower' ] );
__PACKAGE__->attributes( 'single',    [ 'peering_set', 'source' ] );
__PACKAGE__->attributes( 'multiple',  [ 'descr', 'peering', 'mp_peering', 'remarks', 'org', 'tech_c', 'admin_c', 'notify', 'mnt_by', 'mnt_lower', 'changed' ] );


=head1 NAME

Net::Whois::Object::PeeringSet::APNIC - an object representation of the RPSL PeeringSet block

=head1 DESCRIPTION

A peering-set object defines a set of peerings that are listed in its
"peering:" attributes.  The "peering-set:" attribute defines the name
of the set.  It is an RPSL name that starts with "prng-".

=head1 METHODS

=head2 B<new( %options )>

Constructor for the Net::Whois::Object::PeeringSet::APNIC class

=cut

sub new {
    my ( $class, @options ) = @_;

    my $self = bless {}, $class;
    $self->_init(@options);

    return $self;
}

=head2 B<peering_set( [$peering_set] )>

Accessor to the peering_set attribute (the name of the filter set).
Accepts an optional peering_set, always return the current peering_set.

The peering_set must begin with 'PRNG-'.

=head2 B<descr( [$descr] )>

Accessor to the descr attribute.
Accepts an optional descr line to be added to the descr array,
always return the current descr array.

=head2 B<peering( [$peering] )>

Accessor to the peering attribute.
Accepts an optional peering value to be added to the peering array,
always return the current peering array.

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
        always return the current 'mnt_by' array.

=head2 B<changed( [$changed] )>

Accessor to the changed attribute.
Accepts an optional changed value to be added to the changed array,
always return the current changed array.

=head2 B<source( [$source] )>

Accessor to the source attribute.
Accepts an optional source, always return the current source.

=head2 B<mp_peering( [$mp_peering] )>

Accessor to the mp_peering attribute.
Accepts an optional mp_peering value to be added to the mp_peering array,
always return the current mp_peering array.

=head2 B<mnt_lower( [$mnt_lower] )>

Accessor to the mnt_lower attribute.
Accepts an optional mnt_lower value to be added to the mnt_lower array,
always return the current mnt_lower array.

=cut

1;
