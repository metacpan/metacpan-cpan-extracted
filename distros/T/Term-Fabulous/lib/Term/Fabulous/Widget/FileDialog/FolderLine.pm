package Term::Fabulous::Widget::FileDialog::FolderLine;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Display;

our $VERSION = '0.05';

class Term::Fabulous::Widget::FileDialog::FolderLine
	:isa(Term::Fabulous::Widget::Display)
	:strict(params)
{
	use Clay::XS qw(sizing_grow);
	use Term::Fabulous::Check qw(string);
	use Term::Fabulous::Unicode qw(fit_columns);

	use constant CUT => '...';

	field $label :param = 'Folder: ';
	field $path  :param = '';

	ADJUST {
		$label = string( $self, label => $label );
		$path  = string( $self, path  => $path );
	}

	method path (@new) {
		return $path unless @new;
		$path = string( $self, path => $new[0] );
		$self->mark_changed;
		return $path;
	}

	method natural_size () {
		return ( sizing_grow(), 1 );
	}

	# The label, then as much of the end of the path as fits.
	method paint () {
		my $color = $self->color_attr( $self->family_look( text => 'color' ) );
		my $x     = $self->paint_text( 0, 0, $label, $color, undef );
		$self->paint_text( $x, 0, fit_columns( $path, $self->columns - $x, mark => CUT, cut => 'start' ), $color, undef );
		return;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::FileDialog::FolderLine - The line that names
the folder a file dialog shows

=head1 DESCRIPTION

This class is internal to L<Term::Fabulous::Widget::FileDialog>.
Applications never create one themselves.

It is a L<Term::Fabulous::Widget::Display> one row high that grows to
the width of its parent and paints a label (C<Folder:>) and a path in
the theme's C<text.color>. When the path does not fit the width the
line gets, its start is cut off and replaced by C<...> (by
L<Term::Fabulous::Unicode/fit_columns>), so the end of the path, the
folder itself, stays in view; with fewer than three columns for the
path, the C<...> is cut to them. A label too long for the line is cut
at the right.

The file dialog uses one for the folder it shows, and one without a
label for each name in its list, so that a long name keeps its end.

=head1 CONSTRUCTOR

=head2 new

	my $line = Term::Fabulous::Widget::FileDialog::FolderLine->new( path => '/home/ada/notes' );

Accepts the parameters of L<Term::Fabulous::Widget::Display> and two
character strings: C<label> (default C<'Folder: '>) and C<path>
(default C<''>). Unknown parameters die.

=head1 METHODS

=head2 path

	$line->path('/home/ada');

Accessor for the path. Writing paints the line again with the next
frame.

=head1 SEE ALSO

L<Term::Fabulous::Widget::FileDialog>.

=cut
