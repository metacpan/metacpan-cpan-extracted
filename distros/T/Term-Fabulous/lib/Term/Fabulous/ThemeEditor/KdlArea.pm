package Term::Fabulous::ThemeEditor::KdlArea;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Term::Fabulous::Widget::TextArea;

# The text area of the theme editor's text mode: a code editor for KDL
# that keeps Tab for indenting.
class Term::Fabulous::ThemeEditor::KdlArea :isa(Term::Fabulous::Widget::TextArea) :strict(params) {

	# A tab in the text is shown as a blank glyph two columns wide.
	use constant TAB_GLYPH => "\x{3000}";

	# Tab and Shift+Tab indent; they do not move the focus (unless the text
	# cannot be changed, when they move it as everywhere).
	method captures_tab () {
		return $self->read_only ? 0 : 1;
	}

	method display_cluster :override ($cluster) {
		return $cluster eq "\t" ? TAB_GLYPH : $self->SUPER::display_cluster($cluster);
	}

	# The indentation one level adds: the first indentation of the text,
	# or a tab.
	method indent_unit () {
		foreach my $line ( $self->editor->lines ) {
			return $1 if $line =~ /\A([ \t]+)\S/;
		}
		return "\t";
	}

	method handle_key :override ($event) {
		my $name = $event->main_key_name // '';
		return $self->SUPER::handle_key($event) if $self->read_only;
		return $self->_indent_lines(1) if $name eq 'Tab';
		return $self->_indent_lines(-1) if $name eq 'BackTab';
		return $self->_new_line if $name eq 'Enter';
		return $self->_closing_brace if ( $event->text // '' ) eq '}';
		return $self->apply_edit( $self->editor->delete_word_backward ) if $name eq 'Alt+Backspace';
		return $self->_copy if $name eq 'Ctrl+C';
		return 0 if $name eq 'Ctrl+W';    # closes the tab
		return $self->SUPER::handle_key($event);
	}

	method _copy () {
		my $editor = $self->editor;
		return 0 unless $editor->has_selection;
		$editor->copy;
		return 1;
	}

	# A new line with the indentation of the cursor's line, one level more
	# after an opening brace.
	method _new_line () {
		my $editor = $self->editor;
		my ( $row, $offset ) = $editor->cursor;
		my $before   = substr( $editor->line($row), 0, $offset );
		my ($indent) = $before =~ /\A([ \t]*)/;
		$indent .= $self->indent_unit if $before =~ /\{\s*\z/;
		return $self->apply_edit( $editor->insert("\n$indent") );
	}

	# A closing brace typed into the indentation of a line goes one level
	# back.
	method _closing_brace () {
		my $editor = $self->editor;
		my ( $row, $offset ) = $editor->cursor;
		my $before = substr( $editor->line($row), 0, $offset );
		return $self->apply_edit( $editor->type('}') ) if $editor->has_selection || $before !~ /\A[ \t]+\z/;
		my $unit    = $self->indent_unit;
		my $removed = substr( $before, -length $unit ) eq $unit ? length $unit : 1;
		$editor->set_selection( $row, $offset - $removed, $row, $offset );
		return $self->apply_edit( $editor->insert('}') );
	}

	# Indents (1) or outdents (-1) the lines of the selection, or the
	# cursor's line; Tab without a selection inserts one level at the
	# cursor.
	method _indent_lines ($direction) {
		my $editor = $self->editor;
		return $self->apply_edit( $editor->insert( $self->indent_unit ) ) if $direction > 0 && !$editor->has_selection;

		my ( $first, $last ) = $editor->has_selection ? ( $editor->selection )[ 0, 2 ] : ( ( $editor->cursor )[0] ) x 2;
		my @selection = $editor->selection;
		$last-- if @selection && $last > $first && $selection[3] == 0;    # a selection that ends at a line start leaves that line alone
		my $unit = $self->indent_unit;
		my @lines;
		foreach my $row ( $first .. $last ) {
			my $line = $editor->line($row);
			if ( $direction > 0 ) { $line = $unit . $line }
			elsif ( substr( $line, 0, length $unit ) eq $unit ) { substr( $line, 0, length $unit ) = '' }
			elsif ( $line =~ /\A[ \t]/ ) { substr( $line, 0, 1 ) = '' }
			push @lines, $line;
		}
		my $replacement = join "\n", @lines;
		return 1 if $replacement eq join "\n", map { $editor->line($_) } $first .. $last;

		$editor->set_selection( $first, 0, $last, length $editor->line($last) );
		my $changed = $editor->insert($replacement);
		$editor->set_selection( $first, 0, $last, length $editor->line($last) );
		return $self->apply_edit($changed);
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::ThemeEditor::KdlArea - The text area of the theme
editor's text mode

=head1 DESCRIPTION

Part of L<Term::Fabulous::ThemeEditor>; not meant to be used on its
own. A L<Term::Fabulous::Widget::TextArea> for editing a theme file,
which keeps C<Tab> and C<Shift+Tab> (see
L<Term::Fabulous::Manual::Events/Keys Term::Fabulous handles itself>)
and adds these keys to those of the text area:

=over

=item C<Tab>, C<Shift+Tab>

Indent or outdent the selected lines, or the cursor's line; C<Tab>
without a selection inserts one level of indentation at the cursor.

=item C<Enter>

Starts a new line with the indentation of the cursor's line, one level
more after an opening brace.

=item C<}>

Typed into the indentation of a line, takes the line back one level.

=item C<Ctrl+C>

Copies the selection (C<Ctrl+Insert> does too).

=item C<Alt+Backspace>

Deletes the word before the cursor. C<Ctrl+W>, which does that in a
text area, closes the tab in the editor.

=back

One level of indentation is the first indentation found in the text, or
a tab. A tab is shown as a blank two columns wide.

=head1 METHODS

=head2 captures_tab

Returns 1 (0 while the area is read-only): Term::Fabulous leaves C<Tab>
and C<Shift+Tab> to the area.

=head2 indent_unit

The indentation of one level.

=head2 display_cluster

Shows a tab as an ideographic space (U+3000), a blank two columns wide;
the text keeps the tab.

=head2 handle_key

The keys above, then those of L<Term::Fabulous::Widget::TextArea>.

=head1 SEE ALSO

L<Term::Fabulous::ThemeEditor>, L<Term::Fabulous::Widget::TextArea>.

=cut
