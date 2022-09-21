#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2020 -- leonerd@leonerd.org.uk

package Term::VTerm 0.08;

use v5.14;
use warnings;

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

use Exporter 'import';
our @EXPORT_OK; # set up from XS
our %EXPORT_TAGS = (
   types      => [ grep m/^VALUETYPE_/, @EXPORT_OK ],
   attrs      => [ grep m/^ATTR_/, @EXPORT_OK ],
   baselines  => [ grep m/^BASELINE_/, @EXPORT_OK ],
   props      => [ grep m/^PROP_/, @EXPORT_OK ],
   mod        => [ grep m/^MOD_/, @EXPORT_OK ],
   damage     => [ grep m/^DAMAGE_/, @EXPORT_OK ],
   keys       => [ grep m/^KEY_/, @EXPORT_OK ],
   selections => [ grep m/^SELECTION_/, @EXPORT_OK ],
);

=head1 NAME

C<Term::VTerm> - emulate a virtual terminal using F<libvterm>

=cut

=head1 EXPORTED CONSTANTS

The following sets of constants are exported, with the given tag names.

=head2 VALUETYPE_* (:types)

Type constants for the types of C<VTermValue>, as returned by C<get_attr_type>
and C<get_prop_type>.

=head2 ATTR_* (:attrs)

Attribute constants for pen attributes.

=head2 BASELINE_* (:baselines)

Pen attribute value constants for the C<baseline> attribute.

=head2 PROP_* (:props)

Property constants for terminal properties.

=head2 MOD_* (:mod)

Keyboard modifier bitmask constants for C<keyboard_*> and C<mouse_*>.

=head2 DAMAGE_* (:damage)

Size constants for C<VTermScreen> damage merging.

=head2 KEY_* (:keys)

Key symbol constants for C<keyboard_key>.

=head2 SELECTION_* (:selections)

Selection bitmask constants for C<send_selection> and selection callback
events.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $vterm = Term::VTerm->new( %args )

Constructs a new C<Term::VTerm> instance of the initial size given by the
arguments.

=over 8

=item rows, cols => INT

Gives the initial size of the terminal area.

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   defined $args{$_} or croak "Need '$_'"
      for qw( rows cols );

   return $class->_new( @args{qw( rows cols )} );
}

=head1 METHODS

=cut

=head2 get_size

   ( $rows, $cols ) = $vterm->get_size

Returns the current size of the terminal area.

=cut

=head2 set_size

   $vterm->set_size( $rows, $cols )

Sets the new size of the terminal area.

=cut

=head2 get_utf8

=head2 set_utf8

   $utf8 = $vterm->get_utf8

   $vterm->set_utf8( $utf8 )

Return or set UTF-8 mode on the parser.

=cut

=head2 input_write

   $len = $vterm->input_write( $str )

Writes the bytes of the given string into the terminal parser buffer.

=cut

=head2 output_read

   $len = $vterm->output_read( $buf, $maxlen )

Reads bytes from the output buffer of the terminal into the given variable, up
to the maximum length requested. Returns the number of bytes actually read.

=cut

=head2 keyboard_unichar

   $vterm->keyboard_unichar( $char, $mod )

Sends a keypress to the output buffer, encoding the given Unicode character
I<number> (i.e. not a string), with the optional modifier (as a bitmask of one
or more of the C<MOD_*> constants).

=head2 keyboard_key

   $vterm->keyboard_key( $key, $mod )

Sends a keypress to the output buffer, encoding the given key symbol (as a
C<KEY_*> constant), with the optional modifier (as a bitmask of one or more of
the C<MOD_*> constants).

=cut

=head2 mouse_move

   $vterm->mouse_move( $row, $col, $mod )

Moves the mouse cursor to the given position, with optional modifier (as a
bitmask of one or more of the C<MOD_*> constants). It is OK to call this
regardless of the current mouse mode; if the mode doesn't want move report
events or drag events then no output will be generated.

=cut

=head2 mouse_button

   $vterm->mouse_button( $button, $is_pressed, $mod )

Performs a mouse button report event on the given button, to either press or
release it, with optional modifier (as a bitmask of one or more of the
C<MOD_*> constants). It is OK to call this regardless of the current mouse
mode; if mouse reporting is disabled then no output will be generated.

=cut

=head2 parser_set_callbacks

   $vterm->parser_set_callbacks( %cbs )

Sets the parser-layer callbacks. Takes the following named arguments:

=over 8

=item on_text => CODE

   $on_text->( $text )

=item on_control => CODE

   $on_control->( $ctrl )

C<$ctrl> is an integer giving a C0 or C1 control byte value.

=item on_escape => CODE

   $on_escape->( $str )

=item on_csi => CODE

   $on_csi->( $leader, $command, @args )

Where C<$leader> may be C<undef>, and each element of C<@args> is an ARRAY
reference containing sub-arguments. Each sub-argument may be C<undef>.

=item on_osc => CODE

   $on_osc->( $command, $str )

Where C<$command> contains the parsed command number (or -1 if none was found)
and C<$str> contains the full text after the C<;>.

=item on_dcs => CODE

   $on_dcs->( $command, $str )

Where C<$command> contains the parsed DCS command identifier string and
C<$str> contains the full text after it.

=item on_resize => CODE

   $on_resize->( $rows, $cols )

=back

=cut

=head2 obtain_state

   $state = $vterm->obtain_state

Returns a L<Term::VTerm::State> object representing the terminal state layer,
creating it if necessary. After calling this method, any parser callbacks will
no longer work.

=cut

=head2 obtain_screen

   $screen = $vterm->obtain_screen

Returns a L<Term::VTerm::Screen> object representing the terminal screen
layer, creating it if necessary. After calling this method, any parser or
state callbacks will no longer work.

=cut

=head1 FUNCTIONS

The following utility functions are also exported.

=cut

=head2 get_attr_type

   $type = get_attr_type( $attr )

Returns the type of the given pen attribute.

=head2 get_prop_type

   $type = get_prop_type( $prop )

Returns the type of the given terminal property.

=cut

push @EXPORT_OK, qw( get_attr_type get_prop_type );

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
