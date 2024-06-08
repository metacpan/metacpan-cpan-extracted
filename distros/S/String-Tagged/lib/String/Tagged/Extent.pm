#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2008-2022 -- leonerd@leonerd.org.uk

package String::Tagged::Extent 0.23;

use v5.14;
use warnings;

=head1 NAME

C<String::Tagged::Extent> - represents a range within a C<String::Tagged>

=head1 DESCRIPTION

These objects represent a range of characters within the containing
L<String::Tagged> object. The range they represent is fixed at the time of
creation. If the containing string is modified by a call to C<set_substr>
then the effect on the extent object is not defined. These objects should be
considered as relatively short-lived - used briefly for the purpose of
querying the result of an operation, then discarded soon after.

=cut

=head1 METHODS

=cut

=head2 string

   $extent->string;

Returns the containing L<String::Tagged> object.

=cut

sub string
{
   shift->[0]
}

=head2 start

   $extent->start;

Returns the start index of the extent. This is the index of the first
character within the extent.

=cut

sub start
{
   shift->[1]
}

=head2 end

   $extent->end;

Returns the end index of the extent. This is the index of the first character
beyond the end of the extent.

=cut

sub end
{
   shift->[2]
}

=head2 anchor_before

   $extent->anchor_before;

True if this extent begins "before" the start of the string. Only certain
methods return extents with this flag defined.

=cut

sub anchor_before
{
   shift->[3] & String::Tagged::FLAG_ANCHOR_BEFORE;
}

=head2 anchor_after

   $extent->anchor_after;

True if this extent ends "after" the end of the string. Only certain methods
return extents with this flag defined.

=cut

sub anchor_after
{
   shift->[3] & String::Tagged::FLAG_ANCHOR_AFTER;
}

=head2 length

   $extent->length;

Returns the number of characters within the extent.

=cut

sub length
{
   my $self = shift;
   $self->end - $self->start;
}

=head2 substr

   $extent->substr;

Returns the substring contained by the extent, as a L<String::Tagged>
complete with all the relevant tag values.

=cut

sub substr
{
   my $self = shift;
   $self->string->substr( $self->start, $self->length );
}

=head2 plain_substr

   $extent->plain_substr;

Returns the substring of the underlying plain string buffer contained by the
extent, as a plain Perl string.

=cut

sub plain_substr
{
   my $self = shift;
   $self->string->plain_substr( $self->start, $self->length );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
