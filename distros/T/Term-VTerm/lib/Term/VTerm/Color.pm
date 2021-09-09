#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Term::VTerm::Color 0.07;

use v5.14;
use warnings;

require Term::VTerm;

=head1 NAME

C<Term::VTerm::Color> - represent an onscreen color for C<Term::VTerm>

=head1 CONSTRUCTOR

=cut

=head2 new

   $color = Term::VTerm::Color->new( red => $r, green => $g, blue => $b )

Returns a new C<Term::VTerm::Color> instance.

=cut

sub new
{
   my ( $class, %args ) = @_;
   $class->_new_rgb( $args{red}, $args{green}, $args{blue} );
}

=head1 ACCESSORS

=cut

=head2 is_indexed

   $bool = $color->is_indexed

True if the colour is a palette index.

=head2 is_rgb

   $bool = $color->is_rgb

True if the colour contains RGB values directly.

=head2 index

   $idx = $color->index

The palette index for indexed colours.

=head2 red

=head2 green

=head2 blue

   $r = $color->red

   $g = $color->green

   $b = $color->blue

The components of the colour as an integer between 0 and 255 for RGB colours.

=head2 rgb_hex

   $hex = $color->rgb_hex

A 6-character string containing the three colour components, hex encoded.

=cut

sub rgb_hex
{
   my $self = shift;
   sprintf "%02x%02x%02x", $self->red, $self->green, $self->blue
}

=head2 is_default_fg

=head2 is_default_bg

   $bool = $color->is_default_fg

   $bool = $color->is_default_bg

True if the colour is the default colour for terminal foreground or
background.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
