package Term::Fabulous::Unicode;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Exporter 'import';
our @EXPORT_OK = qw(sanitize_text grapheme_clusters cluster_columns string_columns fit_columns terminal_is_utf8 ELLIPSIS);

use I18N::Langinfo qw(langinfo CODESET);
use Term::Fabulous::Termbox qw(tb_cluster_width);
use Unicode::GCString;

use constant CACHE_LIMIT => 4096;
use constant ELLIPSIS    => "\x{2026}";

# The same texts are segmented and measured on every frame (layout
# callbacks, text and canvas drawing), so each result is remembered per
# input string. A cache is emptied once it reaches CACHE_LIMIT entries.
my ( %clusters_by_text, %columns_by_cluster, %columns_by_text );

sub sanitize_text ($text) {
	die "Term::Fabulous::Unicode: sanitize_text needs well-formed UTF-8" unless utf8::valid($text);
	return $text =~ tr/\t\x00-\x08\x0A-\x1F\x7F-\x9F/ \x{FFFD}/r;
}

sub grapheme_clusters ($text) {
	my $clusters = $clusters_by_text{$text};
	return @$clusters if defined $clusters;

	%clusters_by_text = () if keys(%clusters_by_text) >= CACHE_LIMIT;
	$clusters         = $clusters_by_text{$text} = [ map { $_->as_string } @{ Unicode::GCString->new( sanitize_text($text) )->as_arrayref } ];
	return @$clusters;
}

sub cluster_columns ($cluster) {
	my $columns = $columns_by_cluster{$cluster};
	return $columns if defined $columns;

	die "Term::Fabulous::Unicode: cluster_columns needs a non-empty cluster" unless length $cluster;
	%columns_by_cluster = () if keys(%columns_by_cluster) >= CACHE_LIMIT;
	return $columns_by_cluster{$cluster} = _terminal_columns($cluster);
}

sub string_columns ($text) {
	my $columns = $columns_by_text{$text};
	return $columns if defined $columns;

	%columns_by_text = () if keys(%columns_by_text) >= CACHE_LIMIT;
	$columns         = 0;
	$columns += cluster_columns($_) foreach grapheme_clusters($text);
	return $columns_by_text{$text} = $columns;
}

sub fit_columns ( $text, $columns, %options ) {
	my @unknown = grep { $_ ne 'mark' && $_ ne 'cut' } sort keys %options;
	die "Term::Fabulous::Unicode: fit_columns does not take @unknown (known: cut mark)" if @unknown;
	die "Term::Fabulous::Unicode: fit_columns needs a text, got " . _named($text) unless _is_text($text);
	die "Term::Fabulous::Unicode: fit_columns needs a whole number of columns, got " . _named($columns) unless _is_text($columns) && $columns =~ /\A-?[0-9]+\z/;
	my $mark = $options{mark} // ELLIPSIS;
	my $cut  = $options{cut}  // 'end';
	die "Term::Fabulous::Unicode: fit_columns mark must be a text, got " . _named($mark) unless _is_text($mark);
	die "Term::Fabulous::Unicode: fit_columns cut must be 'end' or 'start', got " . _named($cut) unless _is_text($cut) && ( $cut eq 'end' || $cut eq 'start' );

	return '' if $columns <= 0;
	return $text if string_columns($text) <= $columns;
	my $room = $columns - string_columns($mark);
	return join '', _clusters_within( $columns, grapheme_clusters($mark) ) if $room < 0;
	return join( '', _clusters_within( $room, grapheme_clusters($text) ) ) . $mark if $cut eq 'end';
	return $mark . join '', reverse _clusters_within( $room, reverse grapheme_clusters($text) );
}

sub terminal_is_utf8 () {
	return langinfo(CODESET) =~ /\Autf-?8\z/i ? 1 : 0;
}

# The leading clusters that fit into $room columns together.
sub _clusters_within ( $room, @clusters ) {
	my @kept;
	foreach my $cluster (@clusters) {
		$room -= cluster_columns($cluster);
		last if $room < 0;
		push @kept, $cluster;
	}
	return @kept;
}

sub _is_text ($value) {
	return defined $value && !ref $value;
}

sub _named ($value) {
	return 'undef' unless defined $value;
	return ( ref($value) =~ /\A[AEIOU]/ ? 'an ' : 'a ' ) . ref($value) . ' reference' if ref $value;
	return "'$value'";
}

# Mirrors termbox2's tb_present(): a cluster advances by tb_cluster_width()
# (its widest codepoint, forced to 1 by a text presentation selector and
# to 2 by an emoji presentation selector, a zero-width joiner or a pair of
# regional indicators), and any result below 1 advances by one column.
sub _terminal_columns ($cluster) {
	my $width = tb_cluster_width($cluster);
	return $width < 1 ? 1 : $width;
}

1;

__END__

=head1 NAME

Term::Fabulous::Unicode - Measure text in terminal cells, exactly as
termbox2 draws it

=head1 SYNOPSIS

	use Term::Fabulous::Unicode qw(sanitize_text grapheme_clusters cluster_columns string_columns fit_columns terminal_is_utf8 ELLIPSIS);

	my $columns  = string_columns("\x{3042}!");          # 3: a wide Hiragana letter and '!'
	my @clusters = grapheme_clusters("e\x{301}x");       # ("e\x{301}", "x"): e with a combining accent, x
	my $width    = cluster_columns("\x{1F600}");          # 2 under a UTF-8 locale
	my $safe     = sanitize_text("a\tb\e]0;title\a");      # "a b\x{FFFD}]0;title\x{FFFD}"
	my $label    = fit_columns( 'Quarterly report', 8 );   # "Quarter\x{2026}"
	my $folder   = fit_columns( '/home/ada/notes', 9, mark => '...', cut => 'start' );    # ".../notes"

	warn "Wide characters will be misaligned\n" unless terminal_is_utf8();

=head1 DESCRIPTION

A terminal shows text in a grid of cells. Most characters take one
cell, but East Asian characters and most emoji take two, and combining
marks (such as an accent written after a letter) take none of their own.
Layout and drawing must agree on these widths, or everything after a
wide character shifts.

termbox2, which draws Term::Fabulous programs, moves its cursor by the
widths its own Unicode tables report: one codepoint by its C<tb_wcwidth>,
a cluster of several codepoints by its C<tb_cluster_width>, which takes
the widest codepoint and then lets a variation selector, a zero-width
joiner or a pair of regional indicators decide between text (1) and
emoji (2) presentation. This module calls those same functions through
L<Term::Fabulous::Termbox>, so the widths it computes are exactly the
widths termbox2 uses, on every platform. Term::Fabulous uses it to
measure text for the layout and to draw text and canvas cells; use it
yourself when you need to know how wide a string will be on screen, for
example to pad a label, or cut it to the room it has with L</fit_columns>.

All functions take and return Perl character strings (decoded text),
not UTF-8 encoded bytes.

=head2 Grapheme clusters

A grapheme cluster is what a reader sees as one character: a letter
plus its combining accents, a flag made of two regional indicator
symbols, an emoji with a skin tone modifier, and so on. Term::Fabulous
never splits a cluster: each one is drawn into one cell (plus the cells
to its right when it is wide). Clusters are found with
L<Unicode::GCString>.

=head2 The locale matters

The widths do not depend on the locale, but the terminal does: termbox2
sends UTF-8, and a terminal running under a non-UTF-8 locale such as
C<C> shows the bytes of a wide character as several narrow ones, so
everything after it shifts. L<Term::Fabulous::Terminal::Termbox/open>
warns when the locale's character set is not UTF-8 (each time the
terminal is opened, but not on Windows, where termbox2 switches the
console to UTF-8 itself); see L</terminal_is_utf8>.

=head1 FUNCTIONS

Nothing is exported by default. Import the functions you need by name.

=head2 sanitize_text

	my $safe = sanitize_text($text);

Returns a copy of C<$text> that is safe to send to the terminal:

=over

=item *

TAB (U+0009) becomes a space.

=item *

Every other C0 control character (U+0000 to U+001F, including the line
breaks U+000A and U+000D and ESC U+001B), DEL (U+007F) and every C1
control character (U+0080 to U+009F) becomes U+FFFD REPLACEMENT
CHARACTER.

=item *

Everything else is unchanged.

=back

Dies with "Term::Fabulous::Unicode: sanitize_text needs well-formed UTF-8"
when C<$text> carries the UTF8 flag over bytes that are not well-formed
UTF-8 (made by C<Encode::_utf8_on> or read through a C<:utf8> layer
instead of C<:encoding(UTF-8)>). Every function below that sanitizes its
argument dies the same way.

Without this, text from a file or a user could contain escape sequences
that change the terminal's title, colors or clipboard, or move the
cursor. Every text Term::Fabulous measures or draws is sanitized this
way, so you do not need to call it for widget text. Note that a line
break inside one line of text (one Text line, one canvas cell) is shown
as U+FFFD; split multi-line text into lines first. Text widgets do this
for you, because Clay breaks their text into lines at C<"\n"> before it
is drawn.

=head2 grapheme_clusters

	my @clusters = grapheme_clusters($text);

Sanitizes C<$text> (see L</sanitize_text>) and returns its grapheme
clusters as a list of character strings, in order. Returns the empty
list for the empty string.

Results are cached per text; the cache is emptied when it reaches 4096
entries.

=head2 cluster_columns

	my $columns = cluster_columns($cluster);

Returns the number of columns termbox2 advances for one grapheme
cluster: the L<C<tb_cluster_width>|Term::Fabulous::Termbox/tb_cluster_width> of its code
points (the widest one; 1 when a variation selector 15 asks for text
presentation, 2 when a variation selector 16, a zero-width joiner or a
pair of regional indicators asks for emoji presentation), and at least 1
in any case. Zero-width and unprintable clusters therefore still occupy
one cell. The argument should be a single cluster as returned by
L</grapheme_clusters>. Dies if C<$cluster> is the empty string.

Results are cached per cluster; the cache is emptied when it reaches
4096 entries.

=head2 string_columns

	my $columns = string_columns($text);

Returns the number of columns C<$text> occupies on screen: the sum of
L</cluster_columns> over all L</grapheme_clusters> of C<$text>. Returns
0 for the empty string. This is the width Term::Fabulous reports to Clay
for layout.

Results are cached per text; the cache is emptied when it reaches 4096
entries.

=head2 fit_columns

	my $shown = fit_columns( $text, $columns );
	my $shown = fit_columns( $text, $columns, mark => '~', cut => 'start' );

Returns C<$text> cut to at most C<$columns> columns (measured by
L</string_columns>), with a mark where it was cut:

=over

=item *

A text that fits is returned unchanged.

=item *

Otherwise as many whole grapheme clusters as fit together with the mark
are kept: from the start of the text followed by the mark (C<< cut =>
'end' >>, the default), or from its end after the mark (C<< cut =>
'start' >>, for a path whose end matters). A cluster is never split, so a
wide character that does not fit leaves its column empty and the result
is a column narrower than the room. The clusters come from
L</grapheme_clusters>, so a cut text is sanitized.

=item *

C<mark> is the text that shows the cut, by default L</ELLIPSIS>. When
the mark alone is wider than the room, the mark itself is cut at its
end to the room (C<'...'> into two columns gives C<'..'>).

=item *

No room (C<$columns> 0 or less) gives the empty string.

=back

The result is never wider than C<$columns>. Dies with a message that
starts with C<Term::Fabulous::Unicode: fit_columns> when C<$text> or
C<mark> is not a string, C<$columns> is not a whole number, C<cut> is
neither C<'end'> nor C<'start'>, or another option is given.

The status bar, the document tabs, chart texts, the C<truncate> mutator
(L<Term::Fabulous::Widget::Table::Mutator/truncate>), the file dialog's
folder line and the theme editor's settings list cut their texts with
it.

=head2 ELLIPSIS

	use Term::Fabulous::Unicode qw(ELLIPSIS);

The constant C<"\x{2026}"> (HORIZONTAL ELLIPSIS, one column): the mark
L</fit_columns> puts where it cuts unless it is given another.

=head2 terminal_is_utf8

	warn "Wide characters will be misaligned\n" unless terminal_is_utf8();

Returns 1 when the character set of the current locale
(C<langinfo(CODESET)>) is UTF-8, and 0 otherwise. Without a UTF-8
locale, termbox2 cannot place wide characters correctly.

=head1 SEE ALSO

L<Term::Fabulous::Manual::Looks/Wide characters and emoji>,
L<Term::Fabulous::Manual::Looks/Control characters>, L<Term::Fabulous::Termbox>,
L<Unicode::GCString>.

=cut
