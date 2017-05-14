package Net::Whois::Object::Limerick;

use base qw/Net::Whois::Object/;

# RIPE: Deprecated
#
#
# limerick:      [mandatory]  [single]     [primary/look-up key]
# descr:         [optional]   [multiple]   [ ]
# text:          [mandatory]  [multiple]   [ ]
# admin-c:       [mandatory]  [multiple]   [inverse key]
# author:        [mandatory]  [multiple]   [inverse key]
# remarks:       [optional]   [multiple]   [ ]
# notify:        [optional]   [multiple]   [inverse key]
# mnt-by:        [mandatory]  [multiple]   [inverse key]
# changed:       [mandatory]  [multiple]   [ ]
# source:        [mandatory]  [single]     [ ]
__PACKAGE__->attributes( 'primary', ['limerick'] );
__PACKAGE__->attributes( 'mandatory', [ 'limerick', 'text', 'admin_c', 'author', 'mnt_by', 'changed', 'source' ] );
__PACKAGE__->attributes( 'optional', [ 'descr', 'remarks', 'notify' ] );
__PACKAGE__->attributes( 'single', [ 'limerick', 'source' ] );
__PACKAGE__->attributes( 'multiple', [ 'text', 'admin_c', 'author', 'mnt_by', 'changed', 'descr', 'remarks', 'notify' ] );

=head1 NAME

Net::Whois::Object::Limerick - an object representation of the RPSL Limerick block

=head1 DESCRIPTION

The limerick object represents a humorous poem that has five lines and
the rhyme scheme "aabba".

=head1 METHODS

=head2 B<new( %options )>

Constructor for the Net::Whois::Object::Limerick class

=cut

sub new {
    my ( $class, @options ) = @_;

    my $self = bless {}, $class;
    $self->_init(@options);


    return $self;

}

=head2 B<limerick( [$limerick] )>

Accessor to the limerick attribute.
Accepts an optional value, always return the current limerick value.

=head2 B<descr( [$descr] )>

Accessor to the descr attribute.
Accepts an optional descr to be added to the descr array,
always return the current descr array.

=head2 B<text( [$text] )>

Accessor to the text attribute.
Accepts an optional text to be added to the text array,
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

=cut

1;
