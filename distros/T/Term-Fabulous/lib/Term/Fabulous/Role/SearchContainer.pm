package Term::Fabulous::Role::SearchContainer;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Term::Fabulous::Role::Searchable;

role Term::Fabulous::Role::SearchContainer
	:does(Term::Fabulous::Role::Searchable)
{
	use Term::Fabulous::Role::Searchable qw(nested_part nested_search_texts nested_search_revision nested_highlight_text nested_clear_text_highlights nested_reveal_text);

	# The searchable widgets the container answers for, in order.
	method searchable_parts;

	method search_texts () {
		return nested_search_texts( [ $self->searchable_parts ] );
	}

	method search_revision ($key) {
		return nested_search_revision( [ $self->searchable_parts ], $key );
	}

	method highlight_text ( $key, $ranges ) {
		nested_highlight_text( [ $self->searchable_parts ], $key, $ranges );
		return;
	}

	method clear_text_highlights () {
		nested_clear_text_highlights( [ $self->searchable_parts ] );
		return;
	}

	# The container first shows the part (reveal_part, when it has one),
	# then the part shows its text.
	method reveal_text ( $key, $offset ) {
		my @parts = $self->searchable_parts;
		my $part  = nested_part( \@parts, $key );
		$self->reveal_part($part) if defined $part && $self->can('reveal_part');
		return nested_reveal_text( \@parts, $key, $offset );
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Role::SearchContainer - A widget that answers a search
for the searchable widgets inside it

=head1 SYNOPSIS

	use Object::Pad 0.825;
	use Term::Fabulous::Role::SearchContainer;
	use Term::Fabulous::Widget::Box;

	class My::Drawer
		:isa(Term::Fabulous::Widget::Box)
		:does(Term::Fabulous::Role::SearchContainer)
	{
		use Term::Fabulous::Role::Searchable qw(searchables_in);

		field $content = Term::Fabulous::Widget::Box->new;

		method searchable_parts () { return searchables_in($content) }
		method reveal_part ($part) { $self->add_child($content) unless $self->has_child($content); return }
	}

=head1 DESCRIPTION

A container such as a L<Term::Fabulous::Widget::Tabs> or a
L<Term::Fabulous::Widget::Accordion::Item> holds widgets that can be
searched, and some of them may be out of the tree right now (an inactive
page, a closed body). Composing this role makes the container
L<searchable|Term::Fabulous::Role::Searchable> for all of them: it lists
its I<parts>, and the role provides every method of
L<Term::Fabulous::Role::Searchable>, with keys of two parts, the index
of a part and that part's own key (see
L<Term::Fabulous::Role::Searchable/Nested keys>).

The revision of a key names the part at the index as well, so a key
that leads to another part after the parts changed reads as changed
(see L<Term::Fabulous::Role::Searchable/nested_search_revision>).

=head1 REQUIRED METHODS

=head2 searchable_parts

	method searchable_parts () { return map { searchables_in($_) } @pages }

The searchable widgets the container answers for, in the order their
texts appear, also those that are not in the tree now. Called for every
search request, so it lists the parts as they are at that moment.

=head1 OPTIONAL METHODS

=head2 reveal_part

	method reveal_part ($part) { $self->open(1); return }

Called by L</reveal_text> with the part that holds the text, before the
part reveals the text itself: the container makes the part visible (a
Tabs activates the page that holds it, an accordion item opens). A
container without the method shows its parts all the time.

=head1 PROVIDED METHODS

=head2 search_texts, search_revision, highlight_text, clear_text_highlights

The methods of L<Term::Fabulous::Role::Searchable>, answered for the
parts with keys C<[ $index, $key ]>. A key whose index is past the parts
gives the revision C<'gone'> and highlights nothing.

=head2 reveal_text

	my ( $shown, $row ) = @{ $container->reveal_text( $key, $offset ) };

Calls L</reveal_part> with the part the key names (when the container
has the method), then the part's own C<reveal_text>, and returns what
the part returns. A key whose index is past the parts reveals nothing
and returns C<[ undef, undef ]>.

=head1 SEE ALSO

L<Term::Fabulous::Role::Searchable>, L<Term::Fabulous::Widget::Tabs>,
L<Term::Fabulous::Widget::Accordion::Item>,
L<Term::Fabulous::Manual::CustomWidgets/Widgets a search finds>.

=cut
