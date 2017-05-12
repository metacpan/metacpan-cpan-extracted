package Net::Whois::Object::Organisation::APNIC;

use base qw/Net::Whois::Object::Organisation/;

# whois -h whois.apnic.net -t organisation
# % [whois.apnic.net]
# % Whois data copyright terms    http://www.apnic.net/db/dbcopyright.html
# 
# organisation:   [mandatory]  [single]     [primary/lookup key]
# org-name:       [mandatory]  [single]     [lookup key]
# org-type:       [mandatory]  [single]     [ ]
# descr:          [optional]   [multiple]   [ ]
# country:        [optional]   [multiple]   [ ]
# address:        [mandatory]  [multiple]   [ ]
# phone:          [optional]   [multiple]   [ ]
# fax-no:         [optional]   [multiple]   [ ]
# e-mail:         [mandatory]  [multiple]   [lookup key]
# geoloc:         [optional]   [single]     [ ]
# language:       [optional]   [multiple]   [ ]
# org:            [optional]   [multiple]   [inverse key]
# admin-c:        [optional]   [multiple]   [inverse key]
# tech-c:         [optional]   [multiple]   [inverse key]
# ref-nfy:        [optional]   [multiple]   [inverse key]
# mnt-ref:        [mandatory]  [multiple]   [inverse key]
# notify:         [optional]   [multiple]   [inverse key]
# abuse-mailbox:  [optional]   [multiple]   [inverse key]
# mnt-by:         [mandatory]  [multiple]   [inverse key]
# changed:        [mandatory]  [multiple]   [ ]
# source:         [mandatory]  [single]     [ ]
# 
# % This query was served by the APNIC Whois Service version 1.68.5 (WHOIS2)

__PACKAGE__->attributes( 'primary',   [ 'organisation' ] );
__PACKAGE__->attributes( 'mandatory', [ 'organisation', 'org_name', 'org_type', 'address', 'e_mail', 'mnt_ref', 'mnt_by', 'changed', 'source' ] );
__PACKAGE__->attributes( 'optional',  [ 'descr', 'country', 'phone', 'fax_no', 'geoloc', 'language', 'org', 'admin_c', 'tech_c', 'ref_nfy', 'notify', 'abuse_mailbox' ] );
__PACKAGE__->attributes( 'single',    [ 'organisation', 'org_name', 'org_type', 'geoloc', 'source' ] );
__PACKAGE__->attributes( 'multiple',  [ 'descr', 'country', 'address', 'phone', 'fax_no', 'e_mail', 'language', 'org', 'admin_c', 'tech_c', 'ref_nfy', 'mnt_ref', 'notify', 'abuse_mailbox', 'mnt_by', 'changed' ] );

=head1 NAME

Net::Whois::Object::Organisation - an object representation of the RPSL Organisation block

=head1 DESCRIPTION

The organisation object is designed to provide an easy way of mapping resources to a particular organisaiton.

=head1 METHODS

=head2 B<new( %options )>

Constructor for the Net::Whois::Object::Organisation class

=cut

sub new {
    my ( $class, @options ) = @_;

    my $self = bless {}, $class;
    $self->_init(@options);

    return $self;
}

=head2 B<organisation( [$organisation] )>

Accessor to the organisation attribute.
Accepts an optional organisation, always return the current organisation.

=head2 B<org_name( [$org_name] )>

Accessor to the org_name attribute.
Accepts an optional org_name, always return the current org_name.

=head2 B<org_type( [$org_type] )>

Accessor to the org_type attribute.
Accepts an optional org_type, always return the current org_type.

Possible values are:
IANA for Internet Assigned Numbers Authority, RIR for Regional Internet
Registries, NIR for National Internet Registries, LIR for Local Internet
Registries, and OTHER for all other organisations. 

=head2 B<org( [$org] )>

Accessor to the org attribute.
Accepts an optional org, always return the current org.

Points to an existing organisation object representing the entity that
holds the resource.

The 'ORG-' string followed by 2 to 4 characters, followed by up to 5 digits
followed by a source specification.  The first digit must not be "0".
Source specification starts with "-" followed by source name up to
9-character length.

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

=head2 B<country( [$country] )>

Accessor to the country attribute.
Accepts an optional country to be added to the country array,
always return the current country array.

=head2 B<language( [$language] )>

Accessor to the language attribute.
Accepts an optional language to be added to the language array,
always return the current language array.

=head2 B<admin_c( [$contact] )>

Accessor to the admin_c attribute.
Accepts an optional contact to be added to the admin_c array,
always return the current admin_c array.

=head2 B<tech_c( [$contact] )>

Accessor to the tech_c attribute.
Accepts an optional contact to be added to the tech_c array,
always return the current tech_c array.

=head2 B<descr( [$descr] )>

Accessor to the descr attribute.
Accepts an optional descr line to be added to the descr array,
always return the current descr array.

=head2 B<remarks( [$remark] )>

Accessor to the remarks attribute.
Accepts an optional remark to be added to the remarks array,
always return the current remarks array.

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

=head2 B<ref_nfy( [$ref_nfy] )>

Accessor to the ref_nfy attribute.
Accepts an optional ref_nfy value to be added to the ref_nfy array,
always return the current ref_nfy array.

=head2 B<mnt_ref( [$mnt_ref] )>

Accessor to the mnt_ref attribute.
Accepts an optional mnt_ref value to be added to the mnt_ref array,
always return the current mnt_ref array.

=cut

1;
