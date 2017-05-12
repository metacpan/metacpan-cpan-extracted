package Net::Whois::Object::Irt::APNIC;

use base qw/Net::Whois::Object/;

# whois -t irt -h whois.afrinic.net
# % This is the AfriNIC Whois server.
# 
# irt:            [mandatory]  [single]     [primary/look-up key]
# address:        [mandatory]  [multiple]   [ ]
# phone:          [optional]   [multiple]   [ ]
# fax-no:         [optional]   [multiple]   [ ]
# e-mail:         [mandatory]  [multiple]   [lookup key]
# abuse-mailbox:  [mandatory]  [multiple]   [inverse key]
# signature:      [optional]   [multiple]   [ ]
# encryption:     [optional]   [multiple]   [ ]
# org:            [optional]   [multiple]   [inverse key]
# admin-c:        [mandatory]  [multiple]   [inverse key]
# tech-c:         [mandatory]  [multiple]   [inverse key]
# auth:           [mandatory]  [multiple]   [inverse key]
# remarks:        [optional]   [multiple]   [ ]
# irt-nfy:        [optional]   [multiple]   [inverse key]
# notify:         [optional]   [multiple]   [inverse key]
# mnt-by:         [mandatory]  [multiple]   [inverse key]
# changed:        [mandatory]  [multiple]   [ ]
# source:         [mandatory]  [single]     [ ]

__PACKAGE__->attributes( 'primary',   [ 'irt' ] );
__PACKAGE__->attributes( 'mandatory', [ 'irt', 'address', 'e_mail', 'abuse_mailbox', 'admin_c', 'tech_c', 'auth', 'mnt_by', 'changed', 'source' ] );
__PACKAGE__->attributes( 'optional',  [ 'phone', 'fax_no', 'signature', 'encryption', 'org', 'remarks', 'irt_nfy', 'notify' ] );
__PACKAGE__->attributes( 'single',    [ 'irt', 'source' ] );
__PACKAGE__->attributes( 'multiple',  [ 'address', 'phone', 'fax_no', 'e_mail', 'abuse_mailbox', 'signature', 'encryption', 'org', 'admin_c', 'tech_c', 'auth', 'remarks', 'irt_nfy', 'notify', 'mnt_by', 'changed' ] );

=head1 NAME

Net::Whois::Object::Irt::APNIC - an object representation of the RPSL Irt block

=head1 DESCRIPTION

The irt object is used to provide information about a Computer Security
Incident Response Team (CSIRT).  IRTs or CSIRTs specifically respond to
computer security incident reports and activity.

They are dedicated abuse handling teams, (as distinct from network operational
departments) which review and respond to abuse reports.

=head1 METHODS

=head2 B<new( %options )>

Constructor for the Net::Whois::Object::Irt::APNIC class

=cut

sub new {
    my ( $class, @options ) = @_;

    my $self = bless {}, $class;
    $self->_init(@options);


    return $self;

}

=head2 B<irt( [$irt] )>

Accessor to the irt attribute.
Accepts an optional irt, always return the current irt.

The irt object name starts with "IRT-".

=cut

sub irt {
    my ( $self, $irt ) = @_;
    if ( $irt and $irt !~ /^IRT-/i ) {
        warn "Irt name not valid ($irt) : Should start with 'IRT-'";
    }
    return $self->_single_attribute_setget( 'irt', $irt );
}

=head2 B<address( [$address] )>

Accessor to the address attribute.
Accepts an optional address to be added to the address array,
always return the current address array.

Full postal address of a contact.

You can use any combination of alphanumeric characters.
More than one line can be used.

=cut

sub address {
    my ( $self, $address ) = @_;

    return $self->_multiple_attribute_setget( 'address', $address );
}

=head2 B<phone( [$phone] )>

Accessor to the phone attribute.
Accepts an optional phone number to be added to the phone array,
always return the current phone array.

A contact telephone number.

+ <international code> <area code> <phone #>

+ <international code> <area code> <phone #> ext. <#>

 EXAMPLE
 phone: +681 368 0844 ext. 32

=head2 B<fax_no( [$fax_no] )>

Accessor to the fax_no attribute.
Accepts an optional fax_no to be added to the fax_no array,
always return the current fax_no array.

A contact fax number.

+ <international code> <area code> <fax #>

=head2 B<e_mail( [$e_mail] )>

Accessor to the e_mail attribute.
Accepts an optional e_mail to be added to the e_mail array,
always return the current e_mail array.

A contact email address for non-abuse/technical incidents.

=head2 B<abuse_mailbox( [$abuse_mailbox] )>

Accessor to the abuse_mailbox attribute.
Accepts an optional abuse_mailbox to be added to the abuse_mailbox array,
always return the current abuse_mailbox array.

Specifies the email address to which abuse complaints should be sent.

=head2 B<signature( [$signature] )>

Accessor to the signature attribute.
Accepts an optional signature to be added to the signature array,
always return the current signature array.

References a KeyCert object representing a CSIRT public key used by the
team to sign their correspondence.

=head2 B<encryption( [$encryption] )>

Accessor to the encryption attribute.
Accepts an optional encryption to be added to the encryption array,
always return the current encryption array.

References a KeyCert object representing a CSIRT public key used to encrypt
correspondence sent to the CSIRT.

=head2 B<org( [$org] )>

Accessor to the org attribute.
Accepts an optional org value to be added to the org array,
always return the current org array.

The organisation responsible for this resource.

=head2 B<auth( [$auth] )>

Accessor to the auth attribute.
Accepts an optional auth to be added to the auth array,
always return the current auth array.

The Auth defines an authentication scheme to be used. Any of the current
authentication schemes used by the RIPE Database are allowed.

=head2 B<admin_c( [$contact] )>

Accessor to the admin_c attribute.
Accepts an optional contact to be added to the admin_c array,
always return the current admin_c array.

The NIC-handle of an on-site administrative contact. As more than one person
often fulfills a role function, there may be more than one admin_c listed.

An administrative contact (admin_c) must be someone who is physically
located at the site of the network.

=head2 B<tech_c( [$contact] )>

Accessor to the tech_c attribute.
Accepts an optional contact to be added to the tech_c array,
always return the current tech_c array.

The NIC-handle of a technical contact. As more than one person often fulfills
a role function, there may be more than one tech_c listed.

A technical contact (tech_c) must be a person responsible for the
day-to-day operation of the network, but does not need to be
physically located at the site of the network.

=head2 B<remarks( [$remark] )>

Accessor to the remarks attribute.
Accepts an optional remark to be added to the remarks array,
always return the current remarks array.

Information about the object that cannot be stated in other attributes.

=head2 B<notify( [$notify] )>

Accessor to the notify attribute.
Accepts an optional notify value to be added to the notify array,
always return the current notify array.

The email address to which notifications of changes to this object should
be sent.

=head2 B<mnt_by( [$mnt_by] )>

Accessor to the mnt_by attribute.
Accepts an optional mnt_by value to be added to the mnt_by array,
always return the current mnt_by array.

Lists a registered Mntner used to authorize and authenticate changes to
this object.

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

=head2 B<irt_nfy( [$irt_nfy] )>

Accessor to the irt_nfy attribute.
Accepts an optional irt_nfy value to be added to the irt_nfy array,
always return the current irt_nfy array.

The irt_nfy attribute specifies the email address to be notified when a
reference to the irt object is added or removed.

=cut

1;
