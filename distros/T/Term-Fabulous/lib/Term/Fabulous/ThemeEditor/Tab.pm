package Term::Fabulous::ThemeEditor::Tab;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

# One theme open in the theme editor: its text (in a text area, whose
# editor keeps the undo history), the document parsed from it, where it
# is saved and what was saved.
class Term::Fabulous::ThemeEditor::Tab :strict(params) {
	use Clay::XS qw(sizing_grow);
	use File::Basename qw(basename);
	use Term::Fabulous::Check qw(describe);
	use Term::Fabulous::Theme;
	use Term::Fabulous::Theme::Document;
	use Term::Fabulous::ThemeEditor::KdlArea;

	field $path     :param :reader = undef;
	field $untitled :param :reader = undef;    # the number of an untitled theme
	field $mode     :param = 'form';

	field $area       :reader;
	field $document   :reader;
	field $saved_text :reader;
	field $saved_stamp;
	field $crlf = 0;
	field $last_valid_theme;
	field $parsed_revision = -1;

	# What the form showed last: the cursor's key, open sections, search.
	field $form_state :reader = {};

	ADJUST :params ( :$text, :$modified = 0 ) {
		die "Term::Fabulous::ThemeEditor::Tab: a tab needs a path or an untitled number" unless defined $path || defined $untitled;
		die "Term::Fabulous::ThemeEditor::Tab: mode must be 'form' or 'text', got " . describe($mode) unless defined $mode && ( $mode eq 'form' || $mode eq 'text' );
		$crlf = _uses_crlf($text);
		$area = Term::Fabulous::ThemeEditor::KdlArea->new(
			value  => $text,
			wrap   => 0,
			layout => { sizing => { width => sizing_grow(), height => sizing_grow() } },
		);
		$saved_text  = $modified     ? undef         : $area->value;
		$saved_stamp = defined $path ? _stamp($path) : undef;
		$self->reparse;
	}

	# Whether every line of a text ends in CRLF (a text that mixes line
	# ends is saved with LF).
	sub _uses_crlf ($text) {
		return $text =~ /\r\n/ && $text !~ /(?<!\r)\n/ ? 1 : 0;
	}

	sub _stamp ($file) {
		my @stat = stat $file;
		return @stat ? join( ':', @stat[ 7, 9 ] ) : undef;
	}

	# ---------------------------------------------------------------------
	# Names and state
	# ---------------------------------------------------------------------

	method title () {
		return defined $path ? basename($path) : "untitled-$untitled";
	}

	method text () {
		return $area->value;
	}

	method is_modified () {
		return !defined $saved_text || $self->text ne $saved_text ? 1 : 0;
	}

	method mode (@new) {
		return $mode unless @new;
		die "Term::Fabulous::ThemeEditor::Tab: mode must be 'form' or 'text', got " . describe( $new[0] ) unless defined $new[0] && ( $new[0] eq 'form' || $new[0] eq 'text' );
		return $mode = $new[0];
	}

	# The theme the preview shows: the document's, or while the text has
	# errors the last one it had without, or the base theme.
	method preview_theme () {
		return $document->theme // $last_valid_theme // Term::Fabulous::Theme->builtin('dark');
	}

	# Whether the preview shows an older state of the text.
	method is_stale () {
		return $document->is_valid ? 0 : 1;
	}

	# ---------------------------------------------------------------------
	# The text
	# ---------------------------------------------------------------------

	# Parses the text again when it changed since it was parsed last;
	# returns 1 when it did.
	method sync () {
		return 0 if $area->editor->text_revision == $parsed_revision;
		$self->reparse;
		return 1;
	}

	method reparse () {
		$parsed_revision = $area->editor->text_revision;
		$document        = Term::Fabulous::Theme::Document->parse( $area->value );
		my $theme = $document->theme;
		$last_valid_theme = $theme if defined $theme;
		return $document;
	}

	# Changes the text to a new one as one undo step, replacing the whole
	# lines that differ, so the cursor and the view stay near the change.
	method change_text ($new) {
		my $old = $self->text;
		return 0 if $old eq $new;
		my ( $start, $old_end, $new_end ) = _changed_lines( $old, $new );
		my $editor = $area->editor;
		$editor->set_selection( _position( $old, $start ), _position( $old, $old_end ) );
		$editor->insert( substr( $new, $start, $new_end - $start ) );
		$area->mark_changed;
		$self->reparse;
		return 1;
	}

	# Changes the document with code that returns a changed document.
	method change_document ($change) {
		$self->sync;
		my $changed = $change->($document);
		return $self->change_text( $changed->text );
	}

	# The range that differs between two texts, widened to whole lines:
	# where it starts, and where it ends in the old and in the new text.
	sub _changed_lines ( $old, $new ) {
		my $limit  = length $old < length $new ? length $old : length $new;
		my $prefix = 0;
		$prefix++ while $prefix < $limit && substr( $old, $prefix, 1 ) eq substr( $new, $prefix, 1 );
		my $suffix = 0;
		$suffix++ while $suffix < $limit - $prefix && substr( $old, -1 - $suffix, 1 ) eq substr( $new, -1 - $suffix, 1 );

		my $start      = $prefix == 0 ? 0 : rindex( $old, "\n", $prefix - 1 ) + 1;
		my $tail_start = length($old) - $suffix;
		my $old_end    = $tail_start == 0 || substr( $old, $tail_start - 1, 1 ) eq "\n" ? $tail_start : index( $old, "\n", $tail_start ) + 1 || length $old;
		my $new_end    = length($new) - ( length($old) - $old_end );
		return ( $start, $old_end, $new_end );
	}

	# ( row, offset ) of a character offset in a text.
	sub _position ( $text, $offset ) {
		my $before = substr( $text, 0, $offset );
		my $row    = ( $before =~ tr/\n// );
		return ( $row, $offset - ( rindex( $before, "\n" ) + 1 ) );
	}

	method undo () {
		return 0 unless $area->editor->undo;
		$area->mark_changed;
		$self->reparse;
		return 1;
	}

	method redo () {
		return 0 unless $area->editor->redo;
		$area->mark_changed;
		$self->reparse;
		return 1;
	}

	method can_undo () {
		return $area->editor->can_undo ? 1 : 0;
	}

	method can_redo () {
		return $area->editor->can_redo ? 1 : 0;
	}

	# ---------------------------------------------------------------------
	# Files
	# ---------------------------------------------------------------------

	# Whether the file changed on the disk since it was read or saved.
	method changed_on_disk () {
		return 0 unless defined $path && defined $saved_stamp;
		my $now = _stamp($path) // return 1;
		return $now eq $saved_stamp ? 0 : 1;
	}

	# Writes the text to a file (in the line ends it was read with) and
	# makes that the tab's file.
	method save ( $target = $path ) {
		die "Term::Fabulous::ThemeEditor::Tab: save needs a file name" unless defined $target && length $target;
		my $text = $self->text;
		Term::Fabulous::Theme::Document->parse( $self->_file_text )->write_file($target);
		$path        = $target;
		$untitled    = undef;
		$saved_text  = $text;
		$saved_stamp = _stamp($target);
		return $self;
	}

	# Reads the file again; its text replaces the tab's as one undo step.
	method revert () {
		die "Term::Fabulous::ThemeEditor::Tab: an untitled theme has no file to revert to" unless defined $path;
		my $file = Term::Fabulous::Theme::Document->read_file($path)->text;
		$crlf = _uses_crlf($file);
		$self->change_text( $file =~ s/\r\n?/\n/gr );
		$saved_text  = $self->text;
		$saved_stamp = _stamp($path);
		return $self;
	}

	# Writes the unsaved text next to the file (or into a directory for an
	# untitled theme) without making that the tab's file; returns the path.
	method write_recovery ($directory) {
		my $target = ( defined $path ? $path : "$directory/" . $self->title . '.kdl' ) . '.unsaved';
		Term::Fabulous::Theme::Document->parse( $self->_file_text )->write_file($target);
		return $target;
	}

	# The text as the file holds it: in the line ends it was read with.
	method _file_text () {
		my $text = $self->text;
		return $crlf ? $text =~ s/\n/\r\n/gr : $text;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::ThemeEditor::Tab - A theme open in the theme editor

=head1 DESCRIPTION

Part of L<Term::Fabulous::ThemeEditor>; not meant to be used on its
own. A tab holds the text of one theme in a
L<Term::Fabulous::ThemeEditor::KdlArea>, whose editor keeps the one undo
history of both modes; the L<Term::Fabulous::Theme::Document> parsed
from it; the file it belongs to and the text last saved there.

=head1 CONSTRUCTOR

=head2 new

	my $tab = Term::Fabulous::ThemeEditor::Tab->new( path => 'ocean.kdl', text => $kdl );
	my $tab = Term::Fabulous::ThemeEditor::Tab->new( untitled => 1, text => $template );

C<path> or C<untitled> (a number) is required; C<text> is the theme's
text, C<mode> (C<form> or C<text>) the mode the tab starts in, and
C<modified> true for a text that is not the file's.

=head1 METHODS

=head2 path, untitled, title

The file, the number of an untitled theme, and the name the tab shows:
the file's base name or C<untitled-N>.

=head2 area, text, document

The text area, its text, and the document last parsed from it.

=head2 mode

The mode the tab shows, C<form> or C<text>; writing sets it.

=head2 form_state

A hash reference the form keeps its state of this tab in.

=head2 saved_text, is_modified

The text last read or saved (C<undef> when there is none), and whether
the text differs from it.

=head2 preview_theme, is_stale

The theme the preview shows (the document's, or while the text has
errors the last valid one), and whether that is an older state.

=head2 sync, reparse

C<reparse> parses the text; C<sync> does so when the text changed since
the last parse and returns whether it did.

=head2 change_text, change_document

Change the text as one undo step, replacing only the lines that differ.
C<change_document> takes code that gets the current document and
returns a changed one.

=head2 undo, redo, can_undo, can_redo

The undo history of the text area's editor.

=head2 changed_on_disk

1 when the file's size or modification time differs from when it was
read or saved last.

=head2 save

Writes the text to the tab's file, or to another one which becomes the
tab's file, in the line ends the file was read with.

=head2 revert

Reads the file again; its text replaces the tab's as one undo step.

=head2 write_recovery

Writes the unsaved text to C<FILE.unsaved> (C<DIRECTORY/untitled-N.kdl.unsaved>
for an untitled theme) and returns that path.

=head1 SEE ALSO

L<Term::Fabulous::ThemeEditor>.

=cut
