use Renard::Incunabula::Common::Setup;
package Renard::Curie::ViewModel::ViewManager::Role::GridView;
# ABSTRACT: A role for the grid view
$Renard::Curie::ViewModel::ViewManager::Role::GridView::VERSION = '0.005';
use Moo::Role;
use Renard::Incunabula::Common::Types qw(PositiveInt);

has number_of_columns => (
	is => 'rw',
	isa => PositiveInt,
	default => sub { 1 },
	trigger => 1, # _trigger_number_of_columns
);

method _trigger_number_of_columns($new_number_of_columns) {
	my $grid_options = $self->view_options->grid_options->cset( columns => $new_number_of_columns );
	my $view_options = $self->view_options->cset( grid_options => $grid_options );
	$self->view_options( $view_options );
}

method set_view_to_continuous_page() {
	my $grid_options = $self->view_options->grid_options->cset( rows => undef );
	my $view_options = $self->view_options->cset( grid_options => $grid_options );
	$self->view_options( $view_options );
}

method set_view_to_single_page() {
	my $grid_options = $self->view_options->grid_options->cset( rows => 1 );
	my $view_options = $self->view_options->cset( grid_options => $grid_options );
	$self->view_options( $view_options );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::ViewModel::ViewManager::Role::GridView - A role for the grid view

=head1 VERSION

version 0.005

=head1 METHODS

=head2 set_view_to_continuous_page

  method set_view_to_continuous_page()

Sets the L</current_view> to L<Renard::Curie::Model::View::Grid> with C<rows>
C<GridOptions> set to C<undef>.

=head2 set_view_to_single_page

  method set_view_to_single_page()

Sets the L</current_view> to L<Renard::Curie::Model::View::Grid> with C<rows>
C<GridOptions> set to C<1>.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
