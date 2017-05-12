package Net::Posterous::Tag;

use base qw(Net::Posterous::Object);
use Class::Accessor "antlers";

=head1 NAME

Net::Posterous::Tag - represent a tag in Net::Posterous

=head1 DESCRIPTION

This is one of those weird bits of Posterous where they represent the same thing in different ways.

In this case there are 3 different ways of representing tags. The other two forms are abstracted away 
and this form only gets used when getting global tabs with C<get_tags()>.

=head1 METHODS

=cut

=head2 id

Get or set the id of this tag.

=cut

has id => ( is => "rw", isa => "Int" );

=head2 tag_string

Get or set the value of this tag.

=cut

has tag_string => ( is => "rw", isa => "Str" );

=head2 count

Get or set the number of posts that have this tag.

=cut

has count => ( is => "rw", isa => "Int" );
1;


