package Term::Fabulous::ThemeEditor::UI;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

use Term::Fabulous;

# The Term::Fabulous of the theme editor: the editor itself draws with the
# UI's theme, the preview of the theme being edited with that theme.
class Term::Fabulous::ThemeEditor::UI :isa(Term::Fabulous) :strict(params) {
	use Scalar::Util qw(blessed refaddr weaken);

	# The widgets whose subtrees show the preview: the preview pane, and the
	# dialogs and toasts opened from it (weakened: they go when closed).
	field %preview_roots;
	field $preview_theme;

	method add_preview_root ($widget) {
		delete @preview_roots{ grep { !defined $preview_roots{$_} } keys %preview_roots };    # roots that are gone
		weaken( $preview_roots{ refaddr $widget } = $widget );
		$self->refresh_looks;
		return $self;
	}

	method preview_theme (@new) {
		return $preview_theme unless @new;
		die "Term::Fabulous::ThemeEditor::UI: the preview theme must be a Term::Fabulous::Theme" unless blessed $new[0] && $new[0]->isa('Term::Fabulous::Theme');
		return $preview_theme if defined $preview_theme && refaddr $preview_theme == refaddr $new[0];
		$preview_theme = $new[0];
		$self->refresh_looks;
		return $preview_theme;
	}

	method is_in_preview ($widget) {
		for ( my $node = $widget; defined $node; $node = $node->can('parent') ? $node->parent : undef ) {
			return 1 if defined $preview_roots{ refaddr $node };
			my $dialog = $node->can('dialog') ? $node->dialog : undef;    # a dialog's backdrop draws as its dialog
			return 1 if defined $dialog && defined $preview_roots{ refaddr $dialog };
		}
		return 0;
	}

	method theme_for :override ($widget) {
		return $self->SUPER::theme_for($widget) unless defined $preview_theme && $self->is_in_preview($widget);
		return $preview_theme;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::ThemeEditor::UI - The UI of the theme editor, with a
preview in another theme

=head1 DESCRIPTION

Part of L<Term::Fabulous::ThemeEditor>; not meant to be used on its
own. A L<Term::Fabulous> whose
L<theme_for|Term::Fabulous::Render/theme_for> gives the widgets of the
preview (the preview pane, and the dialogs and toasts it opens) the
theme being edited, and every other widget the UI's own theme.

=head1 METHODS

=head2 add_preview_root

	$ui->add_preview_root($widget);

Makes the widget and everything below it draw with the preview theme.
The UI keeps a weak reference only.

=head2 preview_theme

	$ui->preview_theme($theme);

Accessor for the theme of the preview. Setting another theme makes the
widgets read their looks again.

=head2 is_in_preview

1 when the widget is in a preview root's subtree, or is the backdrop of
a dialog that is, else 0.

=head2 theme_for

The preview theme for the widgets in the preview, the UI's theme for
the others.

=head1 SEE ALSO

L<Term::Fabulous::ThemeEditor>, L<Term::Fabulous::Render/theme_for>.

=cut
