#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2018 -- leonerd@leonerd.org.uk

package Term::VTerm::State;

use strict;
use warnings;

our $VERSION = '0.03';

=head1 NAME

C<Term::VTerm::State> - provides access to the state layer of F<libvterm>

=cut

=head1 METHODS

=cut

=head2 reset

   $state->reset( $hard )

Resets the terminal state; performing either a soft or hard reset depending on
the (optional) boolean value given.

=cut

=head2 get_cursorpos

   $pos = $state->get_cursorpos

Returns the current cursor position as a C<VTermPos> object.

=head2 get_default_colors

   ( $fg, $bg ) = $state->get_default_colors

Returns the default foreground and background colors from the palette as
instances of C<VTermColor>.

=head2 set_default_colors

   $state->set_default_colors( $fg, $bg )

Sets the default foreground and backgroudn colors to the palette from
instances of C<VTermColor>.

=head2 get_palette_color

   $col = $state->get_palette_color( $index )

Returns the palette color at the given index as an instance of C<VTermColor>.

=head2 get_penattr

   $value = $state->get_penattr( $attr )

Returns the current value of the given pen attribute (as one of the C<ATTR_*>
constants). Boolean, integer or string attributes are represented as native
perl values. Color attributes return an instance of C<VTermColor>.

=head2 set_callbacks

   $state->set_callbacks( %cbs )

Sets the state-layer callbacks. Takes the following named arguments:

=over 8

=item on_putglyph => CODE

 $on_putglyph->( $glyphinfo, $pos )

C<$glyphinfo> is a C<VTermGlyphInfo> structure. C<$pos> is a C<VTermPos>.

=item on_movecursor => CODE

 $on_movecursor->( $pos, $oldpos, $is_visible )

C<$pos> and C<$oldpos> are a C<VTermPos>. C<$is_visible> is a boolean.

=item on_scrollrect => CODE

 $on_scrollrect->( $rect, $downward, $rightward )

C<$rect> is a C<VTermRect> structure. C<$downward> and C<$rightward> are
integers.

=item on_moverect => CODE

 $on_moverect->( $dest, $src )

C<$dest> and C<$src> are C<VTermRect> structures.

=item on_erase => CODE

 $on_erase->( $rect, $is_selective )

C<$rect> is a C<VTermRect> structure. C<$is_selective> is a boolean.

=item on_initpen => CODE

 $on_initpen->()

=item on_setpenattr => CODE

 $on_setpenattr->( $attr, $value )

C<$attr> is one of the C<ATTR_*> constants. The type of C<$value> depends on
the attribute type - see C<get_penattr>.

=item on_settermprop => CODE

 $on_settermprop->( $prop, $value )

C<$prop> is one of the C<PROP_*> constants. The type of C<$value> depends on
the property type - see similar to C<get_penattr>.

=item on_setmousemode => CODE

 $on_setmousemode->( $mode )

C<$mode> is one of the C<MOUSE_*> constants.

=item on_bell => CODE

 $on_bell->()

=item on_setlineinfo => CODE

 $on_setlineinfo->( $row, $lineinfo, $oldlineinfo )

C<$row> is an integer. C<$lineinfo> and C<$oldlineinfo> are C<VTermLineInfo>
structures.

=back

=head2 convert_color_to_rgb

   $col = $state->convert_color_to_rgb( $col )

Converts a C<VTermColor> structure from indexed to RGB form.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
