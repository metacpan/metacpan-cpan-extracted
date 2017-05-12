package Net::Whois::Object::Poem::APNIC;

use base qw/Net::Whois::Object/;

# whois -h whois.apnic.net -t poem
# % [whois.apnic.net]
# % Whois data copyright terms    http://www.apnic.net/db/dbcopyright.html
# 
# poem:           [mandatory]  [single]     [primary/lookup key]
# descr:          [optional]   [multiple]   [ ]
# form:           [mandatory]  [single]     [inverse key]
# text:           [mandatory]  [multiple]   [ ]
# author:         [optional]   [multiple]   [inverse key]
# remarks:        [optional]   [multiple]   [ ]
# notify:         [optional]   [multiple]   [inverse key]
# mnt-by:         [mandatory]  [single]     [inverse key]
# changed:        [mandatory]  [multiple]   [ ]
# source:         [mandatory]  [single]     [ ]
# 
# % This query was served by the APNIC Whois Service version 1.68.5 (WHOIS1)

__PACKAGE__->attributes( 'primary',   [ 'poem' ] );
__PACKAGE__->attributes( 'mandatory', [ 'poem', 'form', 'text', 'mnt_by', 'changed', 'source' ] );
__PACKAGE__->attributes( 'optional',  [ 'descr', 'author', 'remarks', 'notify' ] );
__PACKAGE__->attributes( 'single',    [ 'poem',  'form', 'mnt_by', 'source' ] );
__PACKAGE__->attributes( 'multiple',  [ 'descr', 'text', 'author', 'remarks', 'notify', 'changed' ] );


=head1 NAME

Net::Whois::Object::Poem::APNIC - an object representation of the RPSL Poem block

=head1 DESCRIPTION

The poem object contains a poem that is submitted by a user. This object is
included in the database to show that engineers do have a sense of humour.

=head1 METHODS

=head2 B<new( %options )>

Constructor for the Net::Whois::Object::Poem::APNIC class

=cut

sub new {
    my ( $class, @options ) = @_;

    my $self = bless {}, $class;
    $self->_init(@options);

    return $self;
}

=head2 B<descr( [$descr] )>

Accessor to the descr attribute.
Accepts an optional descr line to be added to the descr array,
always return the current descr array.

=head2 B<text( [$text] )>

Accessor to the text attribute.
Accepts an optional text line to be added to the text array,
always return the current text array.

=head2 B<admin_c( [$contact] )>

Accessor to the admin_c attribute.
Accepts an optional contact to be added to the admin_c array,
always return the current admin_c array.

=head2 B<author( [$author] )>

Accessor to the author attribute.
Accepts an optional author to be added to the author array,
always return the current author array.

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

=head2 B<form( [$form] )>

Accessor to the form attribute.
Accepts an optional form, always return the current form.
This attribute specifies the identifier of a registered poem type.

=head2 B<poem( [$poem] )>

Accessor to the poem attribute.
Accepts an optional poem, always return the current poem.

=cut

1;
