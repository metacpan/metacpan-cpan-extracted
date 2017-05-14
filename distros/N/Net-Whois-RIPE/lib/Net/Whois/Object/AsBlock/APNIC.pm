package Net::Whois::Object::AsBlock::APNIC;

use base qw/Net::Whois::Object/;

# whois -h whois.apnic.net -t as-block
# % [whois.apnic.net]
# % Whois data copyright terms    http://www.apnic.net/db/dbcopyright.html
# 
# as-block:       [mandatory]  [single]     [primary/lookup key]
# descr:          [optional]   [multiple]   [ ]
# remarks:        [optional]   [multiple]   [ ]
# country:        [optional]   [single]     [ ]
# admin-c:        [mandatory]  [multiple]   [inverse key]
# tech-c:         [mandatory]  [multiple]   [inverse key]
# org:            [optional]   [multiple]   [inverse key]
# notify:         [optional]   [multiple]   [inverse key]
# mnt-by:         [mandatory]  [multiple]   [inverse key]
# mnt-lower:      [optional]   [multiple]   [inverse key]
# changed:        [mandatory]  [multiple]   [ ]
# source:         [mandatory]  [single]     [ ]

% This query was served by the APNIC Whois Service version 1.68.5 (WHOIS1)

__PACKAGE__->attributes( 'primary', ['as_block'] );
__PACKAGE__->attributes( 'mandatory', [ 'as_block', 'admin_c', 'tech_c', 'mnt_by', 'changed', 'source' ] );
__PACKAGE__->attributes( 'optional', [ 'descr', 'remarks', 'country', 'org', 'notify', 'mnt_lower' ] );
__PACKAGE__->attributes( 'single', [ 'as_block', 'country', 'source' ] );
__PACKAGE__->attributes( 'multiple', [ 'descr', 'remarks', 'admin_c', 'tech_c', 'org', 'notify', 'mnt_by', 'mnt_lower', 'changed' ] );

=head1 NAME

Net::Whois::Object::AsBlock::APNIC - an object representation of the RPSL AsBlock block

=head1 DESCRIPTION

An as-block object is needed to delegate a range of AS numbers to a
given repository.  This object may be used for authorisation of the
creation of aut-num objects within the range specified by the
"as-block:" attribute.

=head1 METHODS

=head2 B<new( %options )>

Constructor for the Net::Whois::Object::AsBlock::APNIC class

=cut

sub new {
    my ( $class, @options ) = @_;

    my $self = bless {}, $class;
    $self->_init(@options);


    return $self;
}

=head2 B<as_block( [$as_block] )>

Accessor to the as_block attribute.
Accepts an optional as_block, always return the current as_block value.

An as_block is a range of AS numbers delegated to a Regional or National Internet Registry
(NIR).

The AS numbers in the range are subsequently assigned by the registry to
members or end-users in the region.
Information on individual AS numbers within an as-block object are
stored in the appropriate Internet Registry's Whois Database.

=head2 B<descr( [$descr] )>

Accessor to the descr attribute.
Accepts an optional descr, always return the current descr value.

Description of the Internet Registry delegated the range of AS numbers shown
in the as-block.

=head2 B<remarks( [$remarks] )>

Accessor to the remarks attribute.
Accepts an optional remarks to be added to the remarks array,
always return the current remarks array.

Information on the registry that maintains details of AS numbers assigned from
the as-block.

Also includes where to direct a whois client to find further information on
the AS numbers.

=head2 B<tech_c( [$tech_c] )>

Accessor to the tech_c attribute.
Accepts an optional tech_c to be added to the tech_c array,
always return the current tech_c array.

The NIC-handle of a technical contact 'person' or 'role' object.  As more than
one person often fulfills a role function, there may be more than one tech-c
listed.

A technical contact (tech-c) must be a person responsible for the
day-to-day operation of the network, but does not need to be
physically located at the site of the network.


=head2 B<admin_c( [$admin_c])>

Accessor to the admin_c attribute.
Accepts an optional admin_c to be added to the admin_c array,
always return the current admin_c array.

The NIC-handle of an on-site contact 'person' object. As more than one person
often fulfills a role function, there may be more than one admin-c listed.

An administrative contact(admin-c) must be someone who is physically
located at the site of the network.

=head2 B<notify( [$notify] )>

Accessor to the notify attribute.
Accepts an optional value to be added notify array,
        always return the current notify array.

The email address to which notifications of changes 
to the object should be sent.

=head2 B<mnt_lower( [$mnt_lower] )>

Accessor to the mnt_lower attribute.
Accepts an optional mnt_lower value to be added to the mnt_lower array,
always return the current mnt_lower array.

The identifier of a registered 'mntner' object used to authorize the creation
of 'aut-num' objects within the range specified by the as-block.

If no 'mnt-lower' is specified, the 'mnt-by' attribute is used for
authorization.

=head2 B<mnt_by( [$mnt_by] )>

Accessor to the mnt_by attribute.
Accepts an optional mnt_by value to be added to the mnt_by array,
always return the current mnt_by array.

Lists a registered 'mntner' used to authorize and authenticate changes to this
object.

When your database details are protected by a 'mntner' object, then
only persons with access to the security information of that 'mntner'
object will be able to change details.

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

=head2 B<org( [$org] )>

Accessor to the org attribute.
Accepts an optional org, always return the current org.

The organisation entity this object is bound to.

=cut

1;
