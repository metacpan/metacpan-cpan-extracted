#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2012 -- leonerd@leonerd.org.uk

package Term::TermKey;

use strict;
use warnings;

our $VERSION = '0.16';

use Exporter 'import';

require XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

=head1 NAME

C<Term::TermKey> - perl wrapper around C<libtermkey>

=head1 SYNOPSIS

 use Term::TermKey;

 my $tk = Term::TermKey->new( \*STDIN );

 print "Press any key\n";

 $tk->waitkey( my $key );

 print "You pressed: " . $tk->format_key( $key, 0 );

=head1 DESCRIPTION

This module provides a light perl wrapper around the C<libtermkey> library.
This library attempts to provide an abstract way to read keypress events in
terminal-based programs by providing structures that describe keys, rather
than simply returning raw bytes as read from the TTY device.

This version of C<Term::TermKey> requires C<libtermkey> version at least 0.16.

=head2 Multi-byte keys, ambiguous keys, and waittime

Some keypresses generate multiple bytes from the terminal. There is also the
ambiguity between multi-byte CSI or SS3 sequences, and the Escape key itself.
The waittime timer is used to distinguish them.

When some bytes arrive that could be the start of possibly multiple different
keypress events, the library will attempt to wait for more bytes to arrive
that would finish it. If no more bytes arrive after this time, then the bytes
will be reported as events as they stand, even if this results in interpreting
a partially-complete Escape sequence as a literal Escape key followed by some
normal letters or other symbols.

Similarly, if the start of an incomplete UTF-8 sequence arrives when the
library is in UTF-8 mode, this will be reported as the UTF-8 replacement
character (U+FFFD) if it is incomplete after this time.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $tk = Term::TermKey->new( $fh, $flags )

Construct a new C<Term::TermKey> object that wraps the given term handle.
C<$fh> should be either an IO handle reference, an integer referring to a
plain POSIX file descriptor, of C<undef>. C<$flags> is optional, but if given
should contain the flags to pass to C<libtermkey>'s constructor. Assumes a
default of 0 if not supplied. See the C<FLAG_*> constants.

=head2 $tk = Term::TermKey->new_abstract( $termtype, $flags )

Construct a new abstract C<Term::TermKey> object not associated with a
filehandle. Input may be fed to it using the C<push_bytes()> method
rather than C<waitkey()> or C<advisereadable()>. The name of the termtype
should be given in the C<$termtype> string.

=cut

=head1 METHODS

=cut

# The following documents the various XS-implemented methods in TermKey.xs in
# the same order

=head2 $success = $tk->start

=head2 $sucess = $tk->stop

Start or stop IO interactions from the instance. Starting will send the
terminal initialisation sequence and set up C<termios(5)> settings, stopping
will send the terminal shutdown sequence and restore C<termios(5)> back to the
initial values. After construction, a C<Term::TermKey> instance is already
started, but these methods may be used to suspend and resume, for example, on
receipt of a C<SIGTSTP> signal requesting that the application background
itself.

Returns false if it fails; C<$!> will contain an error code.

=head2 $started = $tk->is_started

Returns true if the instance has been started, or false if it is stopped.

=head2 $flags = $tk->get_flags

=head2 $tk->set_flags( $newflags )

Accessor and mutator for the flags. One of the C<FLAG_UTF8> or C<FLAG_RAW>
flags will be set, even if neither was present in the constructor, as in this
case the library will attempt to detect if the current locale is UTF-8 aware
or not.

=cut

=head2 $canonflags = $tk->get_canonflags

=head2 $tk->set_canonflags( $newcanonflags )

Accessor and mutator for the canonicalisation flags.

=cut

=head2 $msec = $tk->get_waittime

=head2 $tk->set_waittime( $msec )

Accessor and mutator for the maximum wait time in miliseconds. The underlying
C<libtermkey> library will have specified a default value when the object was
constructed.

=cut

=head2 $bytes = $tk->get_buffer_remaining

Accessor returning the number of bytes of buffer space remaining in the
buffer; the space in which C<push_bytes> can write.

=head2 $bytes = $tk->get_buffer_size

=head2 $tk->set_buffer_size( $size )

Accessor and mutator to for the total buffer size to store pending bytes. If
the underlying C<termkey_set_buffer_size(3)> call fails, the
C<set_buffer_size> method will throw an exception.

=cut

=head2 $res = $tk->getkey( $key )

Attempt to retrieve a single keypress event from the buffer, and put it in
C<$key>. If successful, will return C<RES_KEY> to indicate that the C<$key>
structure now contains a new keypress event. If C<$key> is an undefined lvalue
(such as a new scalar variable) it will be initialised to contain a new key
structure.

If nothing is in the buffer it will return C<RES_NONE>. If the buffer contains
a partial keypress event which does not yet contain all the bytes required, it
will return C<RES_AGAIN> (see above section about multibyte events). If no
events are ready and the input stream is now closed, will return C<RES_EOF>.

This method will not block, nor will it perform any IO on the underlying file
descriptor. For a normal blocking read, see C<waitkey()>.

=cut

=head2 $res = $tk->getkey_force( $key )

Similar to C<getkey()>, but will not return C<RES_AGAIN> if a partial match
was found. Instead, it will force an interpretation of the bytes, even if this
means interpreting the start of an C<< <Esc> >>-prefixed multibyte sequence as
a literal C<Escape> key followed by normal letters. If C<$key> is an undefined
lvalue (such as a new scalar variable) it will be initialised to contain a new
key structure.

This method will not block, nor will it perform any IO on the underlying file
descriptor. For a normal blocking read, see C<waitkey()>.

=cut

=head2 $res = $tk->waitkey( $key )

Attempt to retrieve a single keypress event from the buffer, or block until
one is available. If successful, will return C<RES_KEY> to indicate that the
C<$key> structure now contains a new keypress event. If an IO error occurs it
will return C<RES_ERROR>, and if the input stream is now closed it will return
C<RES_EOF>.

If C<$key> is an undefined lvalue (such as a new scalar variable) it will be
initialised to contain a new key structure.

=cut

=head2 $res = $tk->advisereadable

Inform the underlying library that new input may be available on the
underlying file descriptor and so it should call C<read()> to obtain it.
Will return C<RES_AGAIN> if it read at least one more byte, C<RES_NONE> if no
more input was found, or C<RES_ERROR> if an IO error occurs.

Normally this method would only be used in programs that want to use
C<Term::TermKey> asynchronously; see the EXAMPLES section. This method
gracefully handles an C<EAGAIN> error from the underlying C<read()> syscall.

=cut

=head2 $len = $tk->push_bytes( $bytes )

Feed more bytes into the input buffer. This is primarily useful for feeding
input into filehandle-less instances, constructed by passing C<undef> or C<-1>
as the filehandle to the constructor. After calling this method, these bytes
will be available to read as keypresses by the C<getkey> method.

=cut

=head2 $str = $tk->get_keyname( $sym )

Returns the name of a key sym, such as returned by
C<< Term::TermKey::Key->sym() >>.

=cut

=head2 $sym = $tk->keyname2sym( $keyname )

Look up the sym for a named key. The result of this method call can be
compared directly against the value returned by
C<< Term::TermKey::Key->sym() >>. Because this method has to perform a linear
search of key names, it is best called rarely, perhaps during program
initialisation, and the result stored for easier comparisons during runtime.

=cut

=head2 ( $cmd, @args ) = $tk->interpret_unknown_csi( $key )

If C<$key> contains an unknown CSI event then its command and arguments are
returned in a list. C<$cmd> will be a string of 1 to 3 characters long,
containing the initial and intermediate characters if present, followed by the
main command character. C<@args> will contain the numerical arguments, where
missing arguments are replaced by -1. If C<$key> does not contain an unknown
CSI event then an empty list is returned.

Note that this method needs to be called immediately after C<getkey> or
C<waitkey>, or at least, before calling either of those methods again. The
actual CSI sequence is retained in the F<libtermkey> buffer, and only
retrieved by this method call. Calling C<getkey> or C<waitkey> again may
overwrite that buffer.

=cut

=head2 $str = $tk->format_key( $key, $format )

Return a string representation of the keypress event in C<$key>, following the
flags given. See the descriptions of the flags, below, for more detail.

This may be useful for matching keypress events against keybindings stored in
a hash. See EXAMPLES section for more detail.

=cut

=head2 $key = $tk->parse_key( $str, $format )

Return a keypress event by parsing the string representation in C<$str>,
following the flags given. This method is an inverse of C<format_key>.

This may be useful for parsing entries from a configuration file or similar.

=cut

=head2 $key = $tk->parse_key_at_pos( $str, $format )

Return a keypress event by parsing the string representation in a region of
C<$str>, following the flags given.

Where C<parse_key> will start at the beginning of the string and requires the
entire input to be consumed, this method will start at the current C<pos()>
position in C<$str> (or at the beginning of the string if none is yet set),
and after a successful parse, will update it to the end of the matched
section. This position does not have to be at the end of the string. C<$str>
must therefore be a real scalar variable, and not a string literal.

This may be useful for incremental parsing of configuration or other data, out
of a larger string.

=cut

=head2 $cmp = $tk->keycmp( $key1, $key2 )

Compares the two given keypress events, returning a number less than, equal
to, or greater than zero, depending on the ordering. Keys are ordered first by
type (unicode, keysym, function, mouse), then by value within that type, then
finally by modifier bits.

This may be useful in C<sort> expressions:

 my @sorted_keys = sort { $tk->keycmp( $a, $b ) } @keys;

=cut

=head1 KEY OBJECTS

The C<Term::TermKey::Key> subclass is used to store a single keypress event.
Objects in this class cannot be changed by perl code. C<getkey()>,
C<getkey_force()> or C<waitkey()> will overwrite the contents of the structure
with a new value.

Keys cannot be constructed, but C<getkey()>, C<getkey_force()> or C<waitkey()>
will place a new key structure in the C<$key> variable if it is undefined when
they are called. C<parse_key()> and C<parse_key_at_pos()> will return new
keys.

=head2 $key->type

The type of event. One of C<TYPE_UNICODE>, C<TYPE_FUNCTION>, C<TYPE_KEYSYM>,
C<TYPE_MOUSE>, C<TYPE_POSITION>, C<TYPE_MODEREPORT>, C<TYPE_UNKNOWN_CSI>.

=head2 $key->type_is_unicode

=head2 $key->type_is_function

=head2 $key->type_is_keysym

=head2 $key->type_is_mouse

=head2 $key->type_is_position

=head2 $key->type_is_modereport

=head2 $key->type_is_unknown_csi

Shortcuts which return a boolean.

=head2 $key->codepoint

The Unicode codepoint number for C<TYPE_UNICODE>, or 0 otherwise.

=head2 $key->number

The function key number for C<TYPE_FUNCTION>, or 0 otherwise.

=head2 $key->sym

The key symbol number for C<TYPE_KEYSYM>, or 0 otherwise. This can be passed
to C<< Term::TermKey->get_keyname() >>, or compared to a result earlier
obtained from C<< Term::TermKey->keyname2sym() >>.

=head2 $key->modifiers

The modifier bitmask. Can be compared against the C<KEYMOD_*> constants.

=head2 $key->modifier_shift

=head2 $key->modifier_alt

=head2 $key->modifier_ctrl

Shortcuts which return a boolean if the appropriate modifier is present.

=head2 $key->utf8

A string representation of the given Unicode codepoint. If the underlying
C<termkey> library is in UTF-8 mode then this will be a UTF-8 string. If it is
in raw mode, then this will be a single raw byte.

=head2 $key->mouseev

=head2 $key->button

The details of a mouse event for C<TYPE_MOUSE>, or C<undef> for other types of
event.

=head2 $key->line

=head2 $key->col

The details of a mouse or position event, or C<undef> for other types of
event.

=head2 $key->termkey

Return the underlying C<Term::TermKey> object this key was retrieved from.

=head2 $str = $key->format( $format )

Returns a string representation of the keypress event, identically to calling
C<format_key> on the underlying C<Term::TermKey> object.

=cut

sub Term::TermKey::Key::format
{
   my $self = shift;
   return $self->termkey->format_key( $self, @_ );
}

=head1 EXPORTED CONSTANTS

The following constant names are all derived from the underlying C<libtermkey>
library. For more detail see the documentation on the library.

These constants are possible values of C<< $key->type >>

=over 4

=item C<TYPE_UNICODE>

a Unicode codepoint

=item C<TYPE_FUNCTION>

a numbered function key

=item C<TYPE_KEYSYM>

a symbolic key

=item C<TYPE_MOUSE>

a mouse movement or button press or release

=item C<TYPE_POSITION>

a cursor position report

=item C<TYPE_MODEREPORT>

an ANSI or DEC mode report

=item C<TYPE_UNKNOWN_CSI>

an unrecognised CSI sequence

=back

These constants are result values from C<getkey()>, C<getkey_force()>,
C<waitkey()> or C<advisereadable()>

=over 4

=item C<RES_NONE>

No key event is ready.

=item C<RES_KEY>

A key event has been provided.

=item C<RES_EOF>

No key events are ready and the terminal has been closed, so no more will
arrive.

=item C<RES_AGAIN>

No key event is ready yet, but a partial one has been found. This is only
returned by C<getkey()>. To obtain the partial result even if it never
completes, call C<getkey_force()>.

=item C<RES_ERROR>

Returned by C<waitkey> or C<advisereadable> if an IO error occurs while trying
to read another key event.

=back

These constants are key modifier masks for C<< $key->modifiers >>

=over 4

=item C<KEYMOD_SHIFT>

=item C<KEYMOD_ALT>

=item C<KEYMOD_CTRL>

Should be obvious ;)

=back

These constants are types of mouse event which may be returned by
C<< $key->mouseev >> or C<interpret_mouse>:

=over 4

=item C<MOUSE_UNKNOWN>

The type of mouse event was not recognised

=item C<MOUSE_PRESS>

The event reports a mouse button being pressed

=item C<MOUSE_DRAG>

The event reports the mouse being moved while a button is held down

=item C<MOUSE_RELEASE>

The event reports the mouse buttons being released, or the mouse moved without
a button held.

=back

These constants are flags for the constructor, C<< Term::TermKey->new >>

=over 4

=item C<FLAG_NOINTERPRET>

Do not attempt to interpret C0 codes into keysyms (ie. C<Backspace>, C<Tab>,
C<Enter>, C<Escape>). Instead report them as plain C<Ctrl-letter> events.

=item C<FLAG_CONVERTKP>

Convert xterm's alternate keypad symbols into the plain ASCII codes they would
represent.

=item C<FLAG_RAW>

Ignore locale settings; do not attempt to recombine UTF-8 sequences. Instead
report only raw values.

=item C<FLAG_UTF8>

Ignore locale settings; force UTF-8 recombining on.

=item C<FLAG_NOTERMIOS>

Even if the terminal file descriptor represents a TTY device, do not call the
C<tcsetattr()> C<termios> function on it to set in canonical input mode.

=item C<FLAG_SPACESYMBOL>

Sets the C<CANON_SPACESYMBOL> canonicalisation flag. See below.

=item C<FLAG_CTRLC>

Disable the C<SIGINT> behaviour of the C<Ctrl-C> key, allowing it to be read
as a modified Unicode keypress.

=item C<FLAG_EINTR>

Disable retry on signal interrupt; instead report it as an error with
C<RES_ERROR> and C<$!> set to C<EINTR>. Without this flag, IO operations will
be retried if interrupted.

=back

These constants are canonicalisation flags for C<set_canonflags> and
C<get_canonflags>

=over 4

=item C<CANON_SPACESYMBOL>

With this flag set, the Space key will appear as a C<TYPE_KEYSYM> key event
whose symname is C<"Space">. Without this flag, it appears as a normal
C<TYPE_UNICODE> character.

=item C<CANON_DELBS>

With this flag set, the ASCII C<DEL> byte is interpreted as the C<"Backspace">
keysym, rather than C<"DEL">. This flag does not affect the interpretation of
ASCII C<BS>, which is always represented as C<"Backspace">.

=back

These constants are flags to C<format_key>

=over 4

=item C<FORMAT_LONGMOD>

Print full modifier names e.g. C<Shift-> instead of abbreviating to C<S->.

=item C<FORMAT_CARETCTRL>

If the only modifier is C<Ctrl> on a plain character, render it as C<^X>.

=item C<FORMAT_ALTISMETA>

Use the name C<Meta> or the letter C<M> instead of C<Alt> or C<A>.

=item C<FORMAT_WRAPBRACKET>

If the key event is a special key instead of unmodified Unicode, wrap it in
C<< <brackets> >>.

=item C<FORMAT_MOUSE_POS>

If the event is a mouse event, also include the cursor position; rendered as
C<@ ($col,$line)>

=item C<FORMAT_VIM>

Shortcut to C<FORMAT_ALTISMETA|FORMAT_WRAPBRACKET>; which gives an output
close to the format the F<vim> editor uses.

=back

=cut

=head1 EXAMPLES

=head2 A simple print-until-C<Ctrl-C> loop

This program just prints every keypress until the user presses C<Ctrl-C>.

 use Term::TermKey qw( FLAG_UTF8 RES_EOF FORMAT_VIM );
 
 my $tk = Term::TermKey->new(\*STDIN);
 
 # ensure perl and libtermkey agree on Unicode handling
 binmode( STDOUT, ":encoding(UTF-8)" ) if $tk->get_flags & FLAG_UTF8;
 
 while( ( my $ret = $tk->waitkey( my $key ) ) != RES_EOF ) {
    print "Got key: ".$tk->format_key( $key, FORMAT_VIM )."\n";
 }

=head2 Configuration of custom keypresses

Because C<format_key()> yields a plain string representation of a keypress it
can be used as a hash key to look up a "handler" routine for the key.

The following implements a simple line input program, though obviously lacking
many features in a true line editor like F<readline>.

 use Term::TermKey qw( FLAG_UTF8 RES_EOF FORMAT_LONGMOD );
 
 my $tk = Term::TermKey->new(\*STDIN);
 
 # ensure perl and libtermkey agree on Unicode handling
 binmode( STDOUT, ":encoding(UTF-8)" ) if $tk->get_flags & FLAG_UTF8;

 my $line = "";

 $| = 1;

 my %key_handlers = (
    "Enter"  => sub { 
       print "\nThe line is: $line\n";
       $line = "";
    },

    "Backspace" => sub {
       return unless length $line;
       substr( $line, -1, 1 ) = "";
       print "\cH \cH"; # erase it
    },

    # other handlers ...
 );
 
 while( ( my $ret = $tk->waitkey( my $key ) ) != RES_EOF ) {
    my $handler = $key_handlers{ $tk->format_key( $key, FORMAT_LONGMOD ) };
    if( $handler ) {
       $handler->( $key );
    }
    elsif( $key->type_is_unicode and !$key->modifiers ) {
       my $char = $key->utf8;

       $line .= $char;
       print $char;
    }
 }

=head2 Asynchronous operation

Because the C<getkey()> method performs no IO itself, it can be combined with
the C<advisereadable()> method in an asynchronous program.

 use IO::Select;
 use Term::TermKey qw(
    FLAG_UTF8 RES_KEY RES_AGAIN RES_EOF FORMAT_VIM
 );
 
 my $select = IO::Select->new();
 
 my $tk = Term::TermKey->new(\*STDIN);
 $select->add(\*STDIN);
 
 # ensure perl and libtermkey agree on Unicode handling
 binmode( STDOUT, ":encoding(UTF-8)" ) if $tk->get_flags & FLAG_UTF8;
 
 sub on_key
 {
    my ( $tk, $key ) = @_;
 
    print "You pressed " . $tk->format_key( $key, FORMAT_VIM ) . "\n";
 }
 
 my $again = 0;
 
 while(1) {
    my $timeout = $again ? $tk->get_waittime/1000 : undef;
    my @ready = $select->can_read($timeout);
 
    if( !@ready ) {
       my $ret;
       while( ( $ret = $tk->getkey_force( my $key ) ) == RES_KEY ) {
          on_key( $tk, $key );
       }
    }
 
    while( my $fh = shift @ready ) {
       if( $fh == \*STDIN ) {
          $tk->advisereadable;
          my $ret;
          while( ( $ret = $tk->getkey( my $key ) ) == RES_KEY ) {
             on_key( $tk, $key );
          }
 
          $again = ( $ret == RES_AGAIN );
          exit if $ret == RES_EOF;
       }
       # Deal with other filehandles here
    }
 }

There may also be more appropriate modules on CPAN for particular event
frameworks; see the C<SEE ALSO> section below.

=cut

=head1 SEE ALSO

=over 4

=item *

L<http://www.leonerd.org.uk/code/libtermkey/> - C<libtermkey> home page

=item *

L<Term::TermKey::Async> - terminal key input using C<libtermkey> with
L<IO::Async>

=item *

L<POE::Wheel::TermKey> - terminal key input using C<libtermkey> with L<POE>

=item *

L<AnyEvent::TermKey> - terminal key input using C<libtermkey> with L<AnyEvent>

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
