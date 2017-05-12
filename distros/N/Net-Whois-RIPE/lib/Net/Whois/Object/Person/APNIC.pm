package Net::Whois::Object::Person::APNIC;

use base qw/Net::Whois::Object/;

# whois -h whois.apnic.net -t person
# % [whois.apnic.net]
# % Whois data copyright terms    http://www.apnic.net/db/dbcopyright.html
# 
# person:         [mandatory]  [single]     [lookup key]
# address:        [mandatory]  [multiple]   [ ]
# country:        [mandatory]  [single]     [ ]
# phone:          [mandatory]  [multiple]   [ ]
# fax-no:         [optional]   [multiple]   [ ]
# e-mail:         [mandatory]  [multiple]   [lookup key]
# org:            [optional]   [multiple]   [inverse key]
# nic-hdl:        [mandatory]  [single]     [primary/lookup key]
# remarks:        [optional]   [multiple]   [ ]
# notify:         [optional]   [multiple]   [inverse key]
# abuse-mailbox:  [optional]   [multiple]   [inverse key]
# mnt-by:         [mandatory]  [multiple]   [inverse key]
# changed:        [mandatory]  [multiple]   [ ]
# source:         [mandatory]  [single]     [ ]
# 
# % This query was served by the APNIC Whois Service version 1.68.5 (WHOIS1)

__PACKAGE__->attributes( 'primary',   [ 'nic_hdl' ] );
__PACKAGE__->attributes( 'mandatory', [ 'person', 'address', 'country', 'phone', 'email', 'nic_hdl', 'mnt_by', 'changed', 'source' ] );
__PACKAGE__->attributes( 'optional',  [ 'fax_no', 'org', 'remarks', 'notify', 'abuse_mailbox' ] );
__PACKAGE__->attributes( 'single',    [ 'person', 'country', 'nic_hdl', 'source' ] );
__PACKAGE__->attributes( 'multiple',  [ 'address', 'phone', 'fax_no', 'e_mail', 'org', 'remarks', 'notify', 'abuse_mailbox', 'mnt_by', 'changed' ] );


=head1 NAME

Net::Whois::Object::Person::APNIC - an object representation of the RPSL Person block

=head1 DESCRIPTION

A person object contains information about technical or administrative
contact responsible for the object where it is referenced. Once the
object is created, the value of the "person:" attribute cannot be
changed.

=head1 METHODS

=head2 B<new( %options )>

Constructor for the Net::Whois::Object::Person::APNIC class

=cut

sub new {
    my ( $class, @options ) = @_;

    my $self = bless {}, $class;
    $self->_init(@options);

    return $self;
}

=head2 B<person( [$person] )>

Accessor to the person attribute.
Accepts an optional person, always return the current person.

=head2 B<address( [$address] )>

Accessor to the address attribute.
Accepts an optional address line to be added to the address array,
always return the current address array.

=head2 B<phone( [$phone] )>

Accessor to the phone attribute.
Accepts an optional phone number to be added to the phone array,
always return the current phone array.

=head2 B<fax_no( [$fax_no] )>

Accessor to the fax_no attribute.
Accepts an optional fax_no to be added to the fax_no array,
always return the current fax_no array.

=head2 B<e_mail( [$e_mail] )>

Accessor to the e_mail attribute.
Accepts an optional e_mail to be added to the e_mail array,
always return the current e_mail array.

=head2 B<org( [$org] )>

Accessor to the org attribute.
Accepts an optional org, always return the current org array.

Points to an existing organisation object representing the entity that
holds the resource.

The 'ORG-' string followed by 2 to 4 characters, followed by up to 5 digits
followed by a source specification.  The first digit must not be "0".
Source specification starts with "-" followed by source name up to
9-character length.

=head2 B<nic_hdl( [$nic_hdl] )>

Accessor to the nic_hdl attribute.
Accepts an optional nic_hdl, always return the current nic_hdl.

=head2 B<remarks( [$remark] )>

Accessor to the remarks attribute.
Accepts an optional remark to be added to the remarks array,
always return the current remarks array.

=head2 B<notify( [$notify] )>

Accessor to the notify attribute.
Accepts an optional notify value to be added to the notify array,
always return the current notify array.

=head2 B<abuse_mailbox( [$abuse_mailbox] )>

Accessor to the abuse_mailbox attribute.
Accepts an optional abuse_mailbox value to be added to the abuse_mailbox array,
always return the current abuse_mailbox array.

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

=cut

1;
