use Renard::Incunabula::Common::Setup;
package Renard::Incunabula::Outline;
# ABSTRACT: Model that represents a document outline
$Renard::Incunabula::Outline::VERSION = '0.005';
use Moo;
use Renard::Incunabula::Common::Types qw(
	ArrayRef Dict
	PositiveOrZeroInt Str Bool
	InstanceOf
	Optional);
use Renard::Incunabula::Document::Types qw(LaxPageNumber);
use Type::Utils qw( declare as where message );
use Module::Load;

my $Outline = declare
	as ArrayRef[Dict[
			level => PositiveOrZeroInt,
			text => Str,
			open => Optional[Bool],
			page => Optional[LaxPageNumber]
		]];
my $OutlineLevelCheck = declare
	as $Outline,
	where {
		my @outline = @$_;
		for my $idx (0..@outline-2) {
			my $current_level = $outline[$idx]{level};
			my $next_level = $outline[$idx + 1]{level};
			if(  $current_level < $next_level
				and $current_level + 1 != $next_level ) {
				# This is a malformed outline. It should not
				# be possible to go down multiple levels at
				# a time.
				return 0;
			}
		}
		return 1;
	},
	message {
		$Outline->validate($_)
			or "Outline item data has malformed levels";
	};

has items => (
	is => 'rw',
	required => 1,
	isa => $OutlineLevelCheck,
);

has tree_store => (
	is => 'lazy', # _build_tree_store
	isa => InstanceOf['Gtk3::TreeStore'],
);


method _build_tree_store() {
	# load Gtk3 dynamically if used outside Gtk3 context
	load 'Gtk3', '-init';

	my $data = Gtk3::TreeStore->new( 'Glib::String', 'Glib::String', );

	my $outline_items = $self->items;
	my $level = 0;
	my $iter = undef;
	my @parents = ();

	for my $item (@$outline_items) {
		no autovivification;

		# If we need to go up to the parent iterators.
		while( @parents && $item->{level} < @parents ) {
			$iter = pop @parents;
		}

		if( $item->{level} > @parents ) {
			# If we need to go one level down to a child.
			# NOTE : This is not a while(...) loop because the
			# outline should only increase one level at a time.
			push @parents, $iter;
			$iter = $data->append($iter);
			$level++;
		} else {
			# We are still at the same level. Just add a new row to
			# that last parent (or undef if we are at the root).
			$iter = $data->append( $parents[-1] // undef );
		}

		$data->set( $iter,
			0 => $item->{text} // '',
			1 => $item->{page} );
	}

	$data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Incunabula::Outline - Model that represents a document outline

=head1 VERSION

version 0.005

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 ATTRIBUTES

=head2 items

An C<ArrayRef[HashRef]> with a simple representation of an outline where each
item of the ArrayRef represents an item in the list of headings displayed in
order.

Each C<HashRef> element is an element of the outline with the structure:

  {
    # The level in the outline that the item is at. Starts at zero (0).
    level => PositiveOrZeroInt,

    # The textual description of the item.
    text  => Str,

    # The page number that the outline item points to.
    page  => LaxPageNumber,
  }

A complete example is:

  [
    {
      level => 0,
      text  => 'Chapter 1',
      page  => 20,
    },
    {
      level => 1,
      text  => 'Section 1.1',
      page  => 25,
    },
    {
      level => 0,
      text  => 'Chapter 2',
      page  => 30,
    },
  ]

which represents the outline

  Chapter 1 .......... 20
    Section 1.1 ...... 25
  Chapter 2 .......... 30

=head2 tree_store

The L<Gtk3::TreeStore> representation for this outline. It holds tree data of
the heading text and page numbers.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
