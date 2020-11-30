#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2018 -- leonerd@leonerd.org.uk

package Term::VTerm::Screen;

use strict;
use warnings;

our $VERSION = '0.06';

=head1 NAME

C<Term::VTerm::Screen> - provides access to the screen layer of F<libvterm>

=cut

=head1 METHODS

=cut

=head2 enable_altscreen

   $screen->enable_altscreen( $enabled )

Controls whether the altscreen buffer is enabled. Doing so allows the DEC
altscreen mode to switch between regular and alternate screen buffers, but
consumes more memory.

=head2 flush_damage

   $screen->flush_damage

Flushes all pending damage through the screen to the damage callback.

=head2 set_damage_merge

   $screen->set_damage_merge( $size )

Sets the damage merge size, as one of the C<DAMAGE_*> constants.

=head2 reset

   $screen->reset( $hard )

Resets the terminal state; performing either a soft or hard reset depending on
the (optional) boolean value given.

=head2 get_cell

   $cell = $screen->get_cell( $pos )

Returns a C<VTermScreenCell> object representing the current state of the cell
at the given location. Note that this is an instantaneous snapshot - the
returned object will not update to reflect later changes in the screen's
state.

=head2 get_text

   $str = $screen->get_text( $rect )

Returns a UTF-8 string containing the text in the screen buffer within the
given C<VTermRect>.

=head2 set_callbacks

   $screen->set_callbacks( %cbs )

Sets the screen-layer callbacks. Takes the following named arguments:

=over 8

=item on_damage => CODE

   $on_damage->( $rect )

C<$rect> is a C<VTermRect> structure.

=item on_moverect => CODE

   $on_moverect->( $dest, $src )

C<$dest> and C<$src> are C<VTermRect> structures.

=item on_movecursor => CODE

   $on_movecursor->( $pos, $oldpos, $is_visible )

C<$pos> and C<$oldpos> are a C<VTermPos>. C<$is_visible> is a boolean.

=item on_settermprop => CODE

   $on_settermprop->( $prop, $value )

C<$prop> is one of the C<PROP_*> constants. The type of C<$value> depends on
the property type - see similar to C<get_penattr>.

=item on_bell => CODE

   $on_bell->()

=item on_resize => CODE

   $on_resize->( $rows, $cols )

=back

=head2 convert_color_to_rgb

   $col = $screen->convert_color_to_rgb( $col )

Converts a C<VTermColor> structure from indexed to RGB form.

=cut

=head1 CELL OBJECTS

A C<VTermScreenCell> instance has the following field accessors:

=head2 @chars = $cell->chars

A list of Unicode character numbers. This list does not include the
terminating 0.

=head2 $str = $cell->str

A UTF-8 string containing the characters (normally just one but it may be
followed by zero-width combining marks).

=head2 $width = $cell->width

The width of the cell in columns. Normally 1, but 2 for a Unicode double-width
character, or the special value of -1 on the "second" cell of such a character.

=head2 $bold = $cell->bold

=head2 $underline = $cell->underline

=head2 $italic = $cell->italic

=head2 $blink = $cell->blink

=head2 $reverse = $cell->reverse

=head2 $strike = $cell->strike

Simple rendering attributes. All are boolean values, except C<underline> which
is an integer between 0 and 2 (to support double-underline).

=head2 $font = $cell->font

Font selection; an integer between 0 and 10.

=head2 $fg = $cell->fg

=head2 $bg = $cell->bg

The foreground and background colours, as C<VTermColor> instances.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
