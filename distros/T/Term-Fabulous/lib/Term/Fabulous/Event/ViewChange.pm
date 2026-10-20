package Term::Fabulous::Event::ViewChange;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::ViewChange :isa(Clay::UI::Events::Event) :strict(params) {
	use Term::Fabulous::Check qw(non_negative_integer string);

	field $top           :param :reader = undef;
	field $bottom        :param :reader = undef;
	field $section       :param :reader = undef;
	field $section_title :param :reader = undef;
	field $percent       :param :reader = 0;
	field $link          :param :reader = undef;
	field $query         :param :reader = undef;
	field $match         :param :reader = undef;
	field $matches       :param :reader = 0;

	ADJUST {
		$top           = non_negative_integer( $self, top     => $top ) if defined $top;
		$bottom        = non_negative_integer( $self, bottom  => $bottom ) if defined $bottom;
		$section       = non_negative_integer( $self, section => $section ) if defined $section;
		$match         = non_negative_integer( $self, match   => $match ) if defined $match;
		$section_title = string( $self, section_title => $section_title ) if defined $section_title;
		die "Term::Fabulous::Event::ViewChange: section and section_title go together; give both or neither" if defined $section != defined $section_title;
		$percent = non_negative_integer( $self, percent => $percent );
		$matches = non_negative_integer( $self, matches => $matches );
		die "Term::Fabulous::Event::ViewChange: percent must be at most 100, got $percent" if $percent > 100;
		die "Term::Fabulous::Event::ViewChange: match $match lies beyond the $matches matches" if defined $match && ( $match < 1 || $match > $matches );

		# A search may find nothing, but every match is of a search.
		$query = string( $self, query => $query ) if defined $query;
		die "Term::Fabulous::Event::ViewChange: query must not be empty" if defined $query && !length $query;
		die "Term::Fabulous::Event::ViewChange: $matches matches without a query" unless defined $query || !$matches;
	}

	method event_name :common () {
		return 'ViewChange';
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Event::ViewChange - Reports that what a document view shows has changed

=head1 SYNOPSIS

	$view->on( ViewChange => sub ($event) {
		my $where = $event->section_title // 'top';
		$status->text( sprintf '%s  %d%%', $where, $event->percent );
		return;
	} );

=head1 DESCRIPTION

A L<Term::Fabulous::Widget::DocumentView> fires C<ViewChange> on itself
after a frame in which what it shows differs from what it reported
last: for example, the user scrolled, selected another link or
searched, or the program gave the view another document. The event
carries a summary of the view with everything a status line or a table
of contents needs, so their listeners do not have to query the view;
L<Term::Fabulous::Widget::DocumentView/view_state> returns the same
fields at any time.
L<Term::Fabulous::Cookbook::Documents/Search a document and show the reader's position (search, ViewChange)>
feeds a status line from it, and
L<Term::Fabulous::Cookbook::DocumentTechniques/Show a table of contents beside the document (sections, KDL)>
moves a mark through a table of contents.

The view learns what a frame showed only after the frame has been
drawn. The event therefore arrives after the frame it describes, and
whatever its listeners change shows in the following frame.

The event is a L<Clay::UI::Events::Event> named C<ViewChange>. Like
every event, it bubbles up to the view's ancestors, and
C<< $event->target >> is the document view.

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Event::ViewChange->new( top => 0, bottom => 20, percent => 0 );

The document view creates these events itself; create one yourself
only to test your listeners. Every parameter is optional: C<percent>
and C<matches> default to 0, all others to C<undef>. The C<name> and
C<bubble_mode> parameters of L<Clay::UI::Events::Event> are accepted
as well. Unknown parameters die, and so do values that are out of
range or inconsistent:

=over

=item *

C<top>, C<bottom>, C<section> and C<match> must be non-negative
integers or C<undef>;

=item *

C<section> and C<section_title> must be given together, or both left
out;

=item *

C<percent> must be an integer from 0 to 100;

=item *

C<matches> must be a non-negative integer, and C<match>, if given, a
number from 1 to C<matches>;

=item *

C<query>, if given, must be a non-empty string, and C<matches> greater
than 0 requires a C<query>.

=back

=head1 METHODS

=head2 top

	my $index = $event->top;

Returns the index of the item at the top of the view, which may be
only partly visible. Returns C<undef> when the view has no document,
when the document has no items, or when the view has not been laid
out yet.

=head2 bottom

	my $index = $event->bottom;

Returns the index of the item at the bottom of the view, which may be
only partly visible, or C<undef> in the same cases as L</top>.

=head2 section

	my $number = $event->section;

Returns the number of the section the top item belongs to, as
L<Term::Fabulous::Document/section_at> counts it, from 0. Returns
C<undef> when the top item comes before the first section, or when
L</top> is C<undef>.

=head2 section_title

	my $title = $event->section_title;

Returns the title of that section. It is defined exactly when
L</section> is, so that a status line can name the section from the
event alone.

=head2 percent

	my $percent = $event->percent;

Returns how far the view is scrolled, as a rounded integer from 0 at
the top to 100 at the end, the way C<less> shows it. The view reports
100 for a document that fits into the view entirely, and before it has
been laid out.

=head2 link

	my $link = $event->link;

Returns the target of the selected link, as the document holds it, or
C<undef> when no link is selected.

=head2 query

	my $text = $event->query;

Returns the text of the current search, or C<undef> when there is no
search. A search may find nothing, so an event can have a query and no
matches, but it never has matches without a query.

=head2 match, matches

	printf "match %d of %d\n", $event->match, $event->matches if $event->matches;

C<matches> returns the number of search matches, 0 without a search.
C<match> returns the number of the current match, counted from 1, or
C<undef> when there is no current match. The view always has a current
match while there are matches.

=head1 SEE ALSO

L<Term::Fabulous::Widget::DocumentView>,
L<Term::Fabulous::Widget::DocumentView/view_state>,
L<Term::Fabulous::Document/"sections, section_count">,
L<Term::Fabulous::Manual::Events>,
L<Term::Fabulous::Cookbook::Documents/Search a document and show the reader's position (search, ViewChange)>,
L<Term::Fabulous::Cookbook::DocumentTechniques/Show a table of contents beside the document (sections, KDL)>.

=cut
