use Renard::Incunabula::Common::Setup;
package Renard::Curie::Model::View::Role::Pageable;
# ABSTRACT: Role for view models that are paged
$Renard::Curie::Model::View::Role::Pageable::VERSION = '0.003';
use Moo::Role;
use Renard::Incunabula::Common::Types qw(Bool PageNumber);

has page_number => (
	is => 'rw',
	isa => PageNumber,
	default => 1,
	trigger => 1 # _trigger_page_number
	);

requires '_trigger_page_number';

method set_current_page_to_first() {
	$self->page_number( $self->document->first_page_number );
}

method set_current_page_to_last() {
	$self->page_number( $self->document->last_page_number );
}

method can_move_to_previous_page() :ReturnType(Bool) {
	$self->page_number > $self->document->first_page_number;
}

method can_move_to_next_page() :ReturnType(Bool) {
	$self->page_number < $self->document->last_page_number;
}

method set_current_page_forward() {
	if( $self->can_move_to_next_page ) {
		$self->page_number( $self->page_number + 1 );
	}
}

method set_current_page_back() {
	if( $self->can_move_to_previous_page ) {
		$self->page_number( $self->page_number - 1 );
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Model::View::Role::Pageable - Role for view models that are paged

=head1 VERSION

version 0.003

=head1 ATTRIBUTES

=head2 page_number

A L<PageNumber|Renard:Curie::Types/PageNumber> for the current page being
drawn.

=head1 METHODS

=head2 set_current_page_to_first

  method set_current_page_to_first()

Sets the page number to the first page of the document.

=head2 set_current_page_to_last

  method set_current_page_to_last()

Sets the current page to the last page of the document.

=head2 can_move_to_previous_page

  method can_move_to_previous_page() :ReturnType(Bool)

Predicate to check if we can decrement the current page number.

=head2 can_move_to_next_page

  method can_move_to_next_page() :ReturnType(Bool)

Predicate to check if we can increment the current page number.

=head2 set_current_page_forward

  method set_current_page_forward()

Increments the current page number if possible.

=head2 set_current_page_back

  method set_current_page_back()

Decrements the current page number if possible.

=begin comment

=method _trigger_page_number

  method _trigger_page_number($new_page_number)

Called whenever the L</page_number> is changed. This allows for telling
the component to retrieve the new page and redraw.

=end comment

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
