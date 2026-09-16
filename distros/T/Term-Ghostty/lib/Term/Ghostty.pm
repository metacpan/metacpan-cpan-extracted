package Term::Ghostty;
use 5.010;
use strict;
use warnings;
use Carp ();
use XSLoader;

our $VERSION = '0.01';

XSLoader::load('Term::Ghostty', $VERSION);

sub CLONE_SKIP { 1 }

sub STORABLE_freeze { Carp::croak('Term::Ghostty objects cannot be serialized or cloned') }

sub get_text { my $self = shift; $self->format(@_, format => 'plain') }
sub get_vt   { my $self = shift; $self->format(@_, format => 'vt') }
sub get_html { my $self = shift; $self->format(@_, format => 'html') }

1;

__END__

=head1 NAME

Term::Ghostty - Headless terminal emulator built on Ghostty's libghostty-vt

=head1 SYNOPSIS

    use Term::Ghostty;

    my $term = Term::Ghostty->new(
        cols         => 80,
        rows         => 24,
        on_pty_write => sub {
            my ($term, $bytes) = @_;
            syswrite $pty, $bytes;    # answers to terminal queries
        },
        on_title_changed => sub {
            my ($term, $title) = @_;
            print "title: $title\n";
        },
    );

    $term->feed($bytes_read_from_a_pty);
    $term->feed("Hello \e[31mGhostty\e[0m!\r\n");

    my $text = $term->get_text;                     # visible screen
    my $all  = $term->get_text(scrollback => 1);    # with history
    my $vt   = $term->get_vt(cursor => 1, style => 1);
    my $html = $term->get_html;

    my ($col, $row) = $term->cursor_pos;
    my $fullscreen  = $term->active_screen eq 'alternate';

    $term->resize(100, 30);

=head1 DESCRIPTION

Term::Ghostty feeds a byte stream through the terminal emulation core of the
L<Ghostty|https://ghostty.org/> terminal, C<libghostty-vt>, and lets you read
back the resulting screen: its text, cursor and modes, or the screen re-encoded
as plain text, VT sequences or HTML. There is no display; use it to drive or
test programs running in a pseudo-terminal, to scrape their output, or to
render captured terminal output.

The library comes from L<Alien::ghostty>. When that module builds it, which is
the default, it is linked statically.

=head1 CONSTRUCTOR

=head2 new

    my $term = Term::Ghostty->new(%options);

Options:

=over 4

=item cols, rows

Size in cells, 1 to 65535. Default 80 x 24.

=item cell_width_px, cell_height_px

Size of one cell in pixels, used only to answer pixel-size queries
(C<CSI 14 t>) and in-band resize reports (mode 2048). Default 0.

=item max_scrollback

Roughly how many rows of history to keep. The library keeps and frees history
in whole pages of a few hundred rows, so the number kept can be off by a page
either way, and rows are counted at the current width. 0 disables the
scrollback; undef keeps the default of about one page. Setting it also lifts
the library's default memory cap, so memory use grows with the content.

=item title, pwd

Initial window title and working directory.

=item on_pty_write, on_title_changed, on_bell, on_pwd_changed

Callbacks, see L</CALLBACKS>.

=back

It croaks on an unknown option, an odd number of arguments, an out-of-range
size, or a callback that is not a code reference.

=head1 METHODS

=head2 feed

    $term->feed($data);

Runs C<$data> through the VT parser. A byte string is processed as raw bytes,
which is what you read from a pseudo-terminal; a character string (one with
the UTF-8 flag) is processed as its UTF-8 encoding. Escape sequences and
multi-byte characters may be split across calls. Malformed UTF-8 shows up as
U+FFFD.

The emulator does not turn C<"\n"> into C<"\r\n">; a pseudo-terminal's line
discipline normally does that. When feeding text from a file or a pipe,
convert the line endings yourself or enable linefeed mode with C<"\e[20h">.

=head2 write

Same as L</feed>.

=head2 write_until_ground

    my ($consumed, $at_ground) = $term->write_until_ground($data);
    my $consumed = $term->write_until_ground($data);

Feeds only the shortest prefix of C<$data> that brings the parser back to its
ground state, the point between sequences where it is safe to inject your own
output. C<$consumed> is the number of bytes processed (of the UTF-8 encoding,
for a character string, so split byte strings rather than character strings
with it); the rest of C<$data> is not processed, so feed it yourself. If the
parser is already at ground, nothing is consumed. C<$at_ground> is false when
all of C<$data> was consumed and the parser is still inside a sequence.

=head2 format

    my $out = $term->format(%options);

Returns the screen as a character string. Rows are joined with C<"\n">
(C<"\r\n"> for VT output); rows below the last one written to are omitted
and rows are not padded to the terminal width.

=over 4

=item format =E<gt> 'plain' | 'vt' | 'html'

Plain text (the default), text with the VT sequences needed to reproduce its
colours and attributes, or HTML. See L</HTML OUTPUT>.

=item scrollback =E<gt> 0 | 1

Include the scrollback history before the visible screen. Default 0.

=item trim =E<gt> 0 | 1

Remove trailing spaces from each row of plain output. Default 1.

=item unwrap =E<gt> 0 | 1

Join rows that were soft-wrapped at the right margin. Default 0.

=item palette =E<gt> 0 | 1

Include the colour palette: a C<< <style> >> block for HTML (default 1), OSC 4
sequences for VT (default 0).

=back

The following options add terminal state to VT output, so that replaying it
into a fresh terminal restores more than the text. They all default to 0:
C<cursor> (cursor position), C<style> (the current SGR attributes), C<modes>,
C<scrolling_region>, C<tabstops>, C<pwd>, C<keyboard>, C<hyperlink>,
C<protection>, C<kitty_keyboard> and C<charsets>.

It croaks on an unknown option or an odd number of arguments.

=head2 get_text

    my $text = $term->get_text(%options);

Same as C<< format(%options, format => 'plain') >>.

=head2 get_vt

Same as C<< format(%options, format => 'vt') >>.

=head2 get_html

Same as C<< format(%options, format => 'html') >>.

=head2 cols

The terminal width in cells.

=head2 rows

The terminal height in cells.

=head2 cursor_x

The cursor column, counted from 0.

=head2 cursor_y

The cursor row, counted from 0 at the top of the visible screen.

=head2 cursor_pos

    my ($col, $row) = $term->cursor_pos;
    my $pos = $term->cursor_pos;    # [$col, $row]

=head2 cursor_visible

True unless the cursor was hidden (DEC mode 25).

=head2 cursor_pending_wrap

True if the cursor is in the last column and the next character will wrap.

=head2 title

    my $title = $term->title;

The window title, set by OSC 0 or OSC 2 or by L</set_title>. An empty string
when there is none.

=head2 set_title

    $term->set_title($title);

Sets the title; C<undef> clears it. Does not call C<on_title_changed>.

=head2 pwd

    my $url = $term->pwd;

The working directory as reported by the program, usually through OSC 7. This
is the raw value from the escape sequence, normally a URL such as
C<file://host/home/me/My%20Dir>, not a decoded path. An empty string when
there is none.

=head2 set_pwd

    $term->set_pwd($url);

Sets the working directory; C<undef> clears it. Does not call
C<on_pwd_changed>.

=head2 resize

    $term->resize($cols, $rows);
    $term->resize($cols, $rows, $cell_width_px, $cell_height_px);

Changes the size. Text on the primary screen is reflowed. The cell pixel
size is kept when not given. If the program enabled in-band resize reports
(mode 2048), the report is sent through C<on_pty_write> during this call.

=head2 reset

Full reset (RIS): clears both screens and the scrollback, and restores the
default modes, attributes, title and working directory. Callbacks and the
size are kept.

=head2 mode

    my $on = $term->mode(25);      # DEC private mode 25
    my $on = $term->mode(4, 1);    # ANSI mode 4

Whether a mode is set. Returns undef for a mode the terminal does not know,
and croaks if the number is not between 0 and 32767.

=head2 active_screen

C<'primary'> or C<'alternate'>. Full-screen programs such as editors and
pagers normally switch to the alternate screen.

=head2 mouse_tracking

True if the program enabled any mouse reporting mode.

=head2 scrollback_rows

Number of rows in the scrollback history.

=head2 lib_version

    my $version = Term::Ghostty->lib_version;

The version of the linked libghostty-vt.

=head2 on_pty_write

    my $old = $term->on_pty_write(sub { ... });
    $term->on_pty_write(undef);
    my $cb = $term->on_pty_write;

Gets or replaces the callback; with an argument, returns the previous one.
See L</CALLBACKS>.

=head2 on_title_changed

Like L</on_pty_write>, for the title callback.

=head2 on_bell

Like L</on_pty_write>, for the bell callback.

=head2 on_pwd_changed

Like L</on_pty_write>, for the working directory callback.

=head1 CALLBACKS

=over 4

=item on_pty_write($term, $bytes)

Bytes the terminal sends back to the program: answers to status queries,
mode reports and so on. Write them to the pseudo-terminal. C<$bytes> is a
byte string.

=item on_title_changed($term, $title)

The title was changed by OSC 0 or OSC 2.

=item on_bell($term)

A BEL character (0x07) outside an escape sequence.

=item on_pwd_changed($term, $url)

The working directory was reported by OSC 7, OSC 9;9 or OSC 1337 CurrentDir.
See L</pwd> for the format.

=back

Callbacks run synchronously inside L</feed>, L</write>,
L</write_until_ground> and L</resize>. Inside a callback the terminal can be
read, and callbacks can be replaced, but methods that change it (C<feed>,
C<write>, C<write_until_ground>, C<resize>, C<reset>, C<set_title>,
C<set_pwd>) croak.

If a callback dies, the rest of the input is still processed, the remaining
callbacks of that call are skipped, and the method rethrows the first error
once the library has returned.

Use the terminal passed as the first argument instead of closing over the
variable that holds it; a closure over that variable creates a reference
cycle and the terminal is never freed.

=head1 QUERIES

With C<on_pty_write> set, the terminal answers device attribute queries
(primary as a VT220 with ANSI colour, C<CSI ? 62 ; 22 c>, secondary and
tertiary), device status and cursor position reports, mode and setting
queries (DECRQM, DECRQSS), palette colour queries (OSC 4), XTVERSION, the
Kitty keyboard query, window size queries (C<CSI 14 t>, C<CSI 16 t>,
C<CSI 18 t>; pixel sizes are 0 unless a cell size was given) and in-band
resize reports. Default colour queries (OSC 10 and 11), clipboard reads
(OSC 52), ENQ and the colour scheme query (C<CSI ? 996 n>) are not answered.

=head1 ENCODING

L</feed> takes bytes or characters as described above. L</format> and its
wrappers, L</title> and L</pwd> return character strings; malformed UTF-8
coming from the program is replaced by U+FFFD. C<on_pty_write> receives
bytes.

=head1 HTML OUTPUT

HTML output is a C<< <div> >> with inline styles. Palette colours refer to the
CSS variables C<--vt-palette-0> to C<--vt-palette-255>, which the
C<< <style> >> block emitted by default defines on C<:root>; pass
C<< palette => 0 >> to define them yourself. Text is HTML-escaped. Hyperlinks
(OSC 8) become C<< <a href> >>; links whose URL does not start with
C<http://>, C<https://>, C<ftp://>, C<mailto:> or C<file://> are emitted
without the C<href>, so a program cannot plant C<javascript:> links in the
page.

=head1 THREADS

A terminal belongs to the thread that created it. New threads get an unusable
copy; create a separate terminal in each thread. Terminals cannot be
serialized or cloned with L<Storable>.

=head1 EXAMPLES

The F<examples> directory of the distribution has scripts that drive
programs in a pseudo-terminal, convert ANSI output to HTML, replay asciinema
recordings and more.

=head1 SEE ALSO

L<Alien::ghostty>, L<Term::VTerm>, L<Ghostty|https://ghostty.org/>

=head1 AUTHOR

vividsnow

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

libghostty-vt, which is linked into this module, is copyright Mitchell
Hashimoto and the Ghostty contributors and is distributed under the MIT
license. It includes third-party code, such as simdutf, Highway and Wuffs,
under their own permissive licenses; see its source for the texts.

=cut
