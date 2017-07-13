use Renard::Incunabula::Common::Setup;
package Renard::Curie::Model::View::Role::SubviewPageable;
# ABSTRACT: Role for view models that are paged
$Renard::Curie::Model::View::Role::SubviewPageable::VERSION = '0.003';
use Moo::Role;
use MooX::HandlesVia;
use Renard::Incunabula::Common::Types qw(Bool PositiveOrZeroInt ArrayRef);

has _subviews => (
	is => 'lazy', # _build__subviews
	isa => ArrayRef,
	clearer => 1, # _clear_subviews
	handles_via => 'Array',
	handles => {
		_number_of_subviews => 'count',
	},
);
requires '_build__subviews';

has _subview_idx => (
	is => 'rw',
	isa => PositiveOrZeroInt,
	default => sub { 0 },
	trigger => 1 # _trigger__subview_idx
	);

requires '_trigger__subview_idx';

method set_current_subview_to_first() {
	$self->_subview_idx( 0 );
}

method set_current_subview_to_last() {
	$self->_subview_idx(  $self->_number_of_subviews - 1 );
}

method can_move_to_previous_subview() :ReturnType(Bool) {
	$self->_subview_idx > 0;
}

method can_move_to_next_subview() :ReturnType(Bool) {
	$self->_subview_idx < $self->_number_of_subviews - 1;
}

method set_current_subview_forward() {
	if( $self->can_move_to_next_subview ) {
		$self->_subview_idx( $self->_subview_idx + 1 );
	}
}

method set_current_subview_back() {
	if( $self->can_move_to_previous_subview ) {
		$self->_subview_idx( $self->_subview_idx - 1 );
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Model::View::Role::SubviewPageable - Role for view models that are paged

=head1 VERSION

version 0.003

=head1 ATTRIBUTES

=head2 _subview_idx

A private attribute that tracks the current subview.

=head1 METHODS

=head2 set_current_subview_to_first

  method set_current_subview_to_first()

Sets the subview to the first subview of the view collection.

=head2 set_current_subview_to_last

  method set_current_subview_to_last()

Sets the subview to the last subview of the view collection.

=head2 can_move_to_previous_subview

  method can_move_to_previous_subview() :ReturnType(Bool)

Predicate to check if we can decrement the current subview index.

=head2 can_move_to_next_subview

  method can_move_to_next_subview() :ReturnType(Bool)

Predicate to check if we can increment the current subview index.

=head2 set_current_subview_forward

  method set_current_subview_forward()

Increments the current subview index if possible.

=head2 set_current_subview_back

  method set_current_subview_back()

Decrements the current subview index if possible.

=begin comment

=method _trigger__subview_idx

  method _trigger__subview_idx($new_subview_idx)

Called whenever the L</_subview_idx> is changed. This allows for telling
the component to retrieve the new subview and redraw.

=end comment

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
