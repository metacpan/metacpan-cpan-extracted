use Renard::Incunabula::Common::Setup;
package Renard::Curie::Model::View::Grid::Subview;
# ABSTRACT: A subview for a grid-layout
$Renard::Curie::Model::View::Grid::Subview::VERSION = '0.004';
use Moo;
use Renard::Incunabula::Common::Types qw(InstanceOf ArrayRef);
use Renard::Incunabula::Frontend::Gtk3::Types qw(SizeRequest);
use List::AllUtils qw(part sum max);

has _grid_view => (
	is => 'ro',
	required => 1,
	isa => InstanceOf['Renard::Curie::Model::View::Grid']
);

has _grid_scheme => (
	is => 'ro',
	required => 1,
);

has _interpage_x => ( is => 'ro', default => sub { 10 }, );
has _interpage_y => ( is => 'ro', default => sub { 10 }, );

has _page_info => (
	is => 'lazy',
	clearer => 1, # _clear_page_info
);

method _build__page_info() {
	my $doc = $self->_grid_view->document;
	my $page_numbers = $self->_grid_scheme->pages;

	my %rendered_page_by_number = map {
		( $_ =>
			$doc->get_rendered_page(
				page_number => $_,
				zoom_level => $self->_grid_view->zoom_level )
		)
	} @$page_numbers;
	my %page_dims_by_number = map {
		$_ => {
			width => $rendered_page_by_number{$_}->width,
			height => $rendered_page_by_number{$_}->height,
		}
	} keys %rendered_page_by_number;

	my @pages_by_row = map {
			my @this_row_page_idx = @$_;
			my @this_row_page_numbers = map {
				$page_numbers->[$_];
			} @this_row_page_idx;
			\@this_row_page_numbers;
		} part {
			int( $_ / $self->_grid_scheme->columns )
		} 0 .. @$page_numbers-1;

	my $max_width = max map { $_->{width} } values %page_dims_by_number;
	my $max_height = max map { $_->{height} } values %page_dims_by_number;

	my $page_info;

	my $widget_dims = { width => -1, height => -1 };
	for my $row_idx (0 .. $self->_grid_scheme->rows - 1) {
		for my $col_idx (0 .. $self->_grid_scheme->columns - 1) {
			if( defined $pages_by_row[$row_idx] && defined $pages_by_row[$row_idx][$col_idx] ) {
				my $page_number = $pages_by_row[$row_idx][$col_idx];

				my $xmin = 0 + ( $max_width + $self->_interpage_x ) * $col_idx;
				my $ymin = 0 + ( $max_height + $self->_interpage_y  ) * $row_idx;

				my $xmax = $xmin + $page_dims_by_number{$page_number}{width};
				my $ymax = $ymin + $page_dims_by_number{$page_number}{height};

				push @$page_info, {
					pageno => $page_number,
					bbox => [ $xmin, $ymin, $xmax, $ymax, ],
				};

				$widget_dims->{width}  = max( $widget_dims->{width} , $xmax );
				$widget_dims->{height} = max( $widget_dims->{height}, $ymax );
			}
		}
	}

	return {
		page_xy => $page_info,
		total_y => $widget_dims->{height},
		largest_x => $widget_dims->{width},
	};
}

method get_size_request() :ReturnType( list => SizeRequest) {
	my $page_info = $self->_page_info;
	return ( $page_info->{largest_x}, $page_info->{total_y} );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Model::View::Grid::Subview - A subview for a grid-layout

=head1 VERSION

version 0.004

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 METHODS

=head2 get_size_request

See L<Renard::Curie::Model::View::Role::Renderable/get_size_request>.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
