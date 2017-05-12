package Net::Whois::Object::PoeticForm::APNIC;

use base qw/Net::Whois::Object/;

# whois -h whois.apnic.net -t poetic-form
# % [whois.apnic.net]
# % Whois data copyright terms    http://www.apnic.net/db/dbcopyright.html
# 
# poetic-form:    [mandatory]  [single]     [primary/lookup key]
# descr:          [optional]   [multiple]   [ ]
# admin-c:        [mandatory]  [multiple]   [inverse key]
# remarks:        [optional]   [multiple]   [ ]
# notify:         [optional]   [multiple]   [inverse key]
# mnt-by:         [mandatory]  [multiple]   [inverse key]
# changed:        [mandatory]  [multiple]   [ ]
# source:         [mandatory]  [single]     [ ]
# 
# % This query was served by the APNIC Whois Service version 1.68.5 (WHOIS1)

__PACKAGE__->attributes( 'primary',   [ 'poetic_form' ] );
__PACKAGE__->attributes( 'mandatory', [ 'poetic_form', 'admin_c', 'mnt_by', 'changed', 'source' ] );
__PACKAGE__->attributes( 'optional',  [ 'descr', 'remarks', 'notify' ] );
__PACKAGE__->attributes( 'single',    [ 'poetic_form', 'source' ] );
__PACKAGE__->attributes( 'multiple',  [ 'descr', 'admin_c', 'remarks', 'notify', 'mnt_by', 'changed' ] );

=head1 NAME

Net::Whois::Object::PoeticForm::APNIC - an object representation of the RPSL PoeticForm block

=head1 DESCRIPTION

The poetic_form object contains a poetic_form that is submitted by a user. This object is
included in the database to show that engineers do have a sense of humour.

=head1 METHODS

=head2 B<new( %options )>

Constructor for the Net::Whois::Object::PoeticForm::APNIC class

=cut

sub new {
    my ( $class, @options ) = @_;

    my $self = bless {}, $class;
    $self->_init(@options);

    return $self;
}

=head2 B<poetic_form( [$poetic_form] )>

Accessor to the poetic_form attribute.
Accepts an optional poetic_form, always return the current poetic_form.

=head2 B<descr( [$descr] )>

Accessor to the descr attribute.
Accepts an optional descr line to be added to the descr array,
always return the current descr array.

=head2 B<admin_c( [$contact] )>

Accessor to the admin_c attribute.
Accepts an optional contact to be added to the admin_c array,
always return the current admin_c array.

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

=cut

1;
