use Renard::Incunabula::Common::Setup;
package Renard::Curie::Model::View::Grid;
# ABSTRACT: A view model for grid-based views
$Renard::Curie::Model::View::Grid::VERSION = '0.004';
use Moo;

use Renard::Incunabula::Common::Types qw(InstanceOf ArrayRef);
use Renard::Incunabula::Frontend::Gtk3::Types qw(SizeRequest);
use POSIX qw(ceil);
use List::AllUtils qw(part first);
use Glib qw(TRUE FALSE);
use Test::Deep::NoTest;

use vars qw($DO_NOT_SCROLL);
$DO_NOT_SCROLL = 0;

use MooX::Struct
	GridScheme => [ qw( rows columns pages) ]
;

use Renard::Curie::Model::View;
use Glib::Object::Subclass
	'Glib::Object',
	signals => { 'view-changed' => {} },
	;
extends 'Renard::Curie::Model::View';

use Renard::Curie::Model::View::Grid::Subview;

classmethod FOREIGNBUILDARGS(@) {
	return ();
}

has view_options => (
	is => 'ro',
	required => 1,
	predicate => 1, # has_view_options
	isa => InstanceOf['Renard::Curie::Model::ViewOptions'],
);

has _grid_schemes => (
	is => 'lazy', # _build__grid_schemes
	isa => ArrayRef, # ArrayRef[GridScheme]
);

method draw_page(
	(InstanceOf['Gtk3::DrawingArea']) $widget,
	(InstanceOf['Cairo::Context']) $cr
) {
	# uncoverable subroutine
	my $p =  $widget->get_parent;
	my $v = $p->get_vadjustment;

	my $view_y_min = $v->get_value;
	my $view_y_max = $v->get_value + $v->get_page_size;

	my $subview = $self->_current_subview;

	$self->_widget_dims([
		$widget->get_allocated_width,
		$widget->get_allocated_height,
	]);
	$subview->_clear_page_info;
	my $page_xy = $subview->_page_info->{page_xy};
	my $zoom_level = $self->zoom_level;
	my @pages_to_render = grep {
		my $page = $_;
		! ( $page->{bbox}[3] < $view_y_min
			|| $page->{bbox}[1] > $view_y_max);
	} @$page_xy;
	for my $page (@pages_to_render) {
		my $rp = $self->document->get_rendered_page(
			page_number => $page->{pageno},
			zoom_level => $zoom_level,
		);

		my $img = $rp->cairo_image_surface;

		$cr->set_source_surface($img,
			$page->{bbox}[0],
			$page->{bbox}[1]);

		$cr->paint;
	}
}

method get_size_request() :ReturnType( list => SizeRequest) {
	return $self->_current_subview->get_size_request;
}

method _current_subview() {
	$self->_subviews->[ $self->_subview_idx ];
}

has _widget_dims => (
	is => 'rw',
	default => sub { [0, 0] },
);


method _build__grid_schemes() {
	my $go_r = $self->view_options->grid_options->rows;
	my $go_c = $self->view_options->grid_options->columns;
	my @page_numbers = ( $self->document->first_page_number .. $self->document->last_page_number);

	my ($g_r, $g_c);
	if( defined $go_r && defined $go_c ) {
		($g_r, $g_c) = ($go_r, $go_c);
	} elsif( defined $go_r && ! defined $go_c ) {
		$g_r = $go_r;
		$g_c = ceil($self->document->number_of_pages / $go_r);
	} elsif( ! defined $go_r && defined $go_c ) {
		$g_r = ceil($self->document->number_of_pages / $go_c);
		$g_c = $go_c;
	} else {
		Renard::Incunabula::Common::Error::Programmer::Logic->new(
			msg => 'GridOption improperly constructed: both row and columns undef',
		);
	}

	my $num_pages_per_view = $g_r * $g_c;
	my $num_views = ceil( $self->document->number_of_pages / $num_pages_per_view );
	my @grid_pages = part { int( $_ / $num_pages_per_view ) } 0 .. @page_numbers - 1;

	my @grid_collection = map {
		my @this_grid_page_idx = @$_;
		my @this_grid_pages = map {
			$page_numbers[$_]
		} @this_grid_page_idx;
		GridScheme->new( rows => $g_r, columns => $g_c, pages => \@this_grid_pages );
	} @grid_pages;

	return \@grid_collection;
}

method _build__subviews() {
	[
		map {
			Renard::Curie::Model::View::Grid::Subview->new(
				_grid_view => $self,
				_grid_scheme => $_,
			);
		} @{ $self->_grid_schemes }
	];
}

has _adjustments => (
	is => 'rw',
	predicate => 1, # _has_adjustments
);

has _last_adjustment_values => (
	is => 'rw',
	default => sub { +{} },
);

has _need_to_scroll => (
	is => 'rw',
	default => sub { 1 },
);

# TODO This is a hack that needs to be refactored.
method update_scroll_adjustment($hadjustment, $vadjustment) {
	$self->_adjustments( [$hadjustment, $vadjustment] );

	my $values = [ map {
		[ $_->get_lower, $_->get_upper, ],
	} ($hadjustment, $vadjustment) ];

	if( ! eq_deeply( $values, $self->_last_adjustment_values ) ) {
		$self->_need_to_scroll(1);
	}

	if( $self->_need_to_scroll ) {
		$self->_scroll_to_page_number( $self->page_number );
	}

	$self->_last_adjustment_values( $values );

	# TODO need to update how page number updates
	#if( ! $DO_NOT_SCROLL ) {
		#local $DO_NOT_SCROLL = 1;
		#my $viewport_page = $self->_first_page_in_viewport;
		#$self->{page_number} = $viewport_page if defined $viewport_page;
	#}
}

method _first_page_in_viewport() {
	my $first_page = $self->_current_subview->_grid_scheme->pages->[0];
	my $top_left = [
		$self->_adjustments->[0]->get_value,
		$self->_adjustments->[1]->get_value ];
	my $page_xy = $self->_current_subview->_page_info->{page_xy};
	my $topleft_page = first {
		my $page = $_;
		$top_left->[0] <= $page->{bbox}[2]
			&& $top_left->[1] <= $page->{bbox}[3];
	} @$page_xy;

	$topleft_page->{pageno};
}

method _trigger__subview_idx() {
	$self->signal_emit( 'view-changed' );
}

method _scroll_to_page_number($page_number) {
	unless($self->has_view_options) {
		$self->_need_to_scroll(1);
		return;
	}

	my $subview_has_page = !! grep {
		$_ == $page_number
	} @{ $self->_grid_schemes->[$self->_subview_idx]->pages };
	if( ! $subview_has_page ) {
		my $idx = first {
			my $idx = $_;
			my $subview_pages = $self->_grid_schemes->[$idx]->pages;
			defined first { $_ == $page_number } @$subview_pages;
		} 0 .. @{ $self->_grid_schemes } - 1;
		$self->_subview_idx( $idx );
	}

	$self->_current_subview;
	my $page_xy = $self->_current_subview->_page_info->{page_xy};
	my $page = first {  $_->{pageno} == $page_number } @$page_xy;

	if( $self->_has_adjustments ) {
		$self->_adjustments->[0]->set_value( $page->{bbox}[0] );
		$self->_adjustments->[1]->set_value( $page->{bbox}[1] );
		$self->_need_to_scroll(0);
	} else {
		$self->_need_to_scroll(1);
	}
}

method _trigger_page_number($page_number) {
	if( ! $DO_NOT_SCROLL ) { # checking local variable
		$self->_scroll_to_page_number($page_number);
	}
	$self->signal_emit( 'view-changed' );
}

method _trigger_zoom_level($new_zoom_level) {
	$self->_clear_subviews;
	$self->signal_emit( 'view-changed' );
}

with qw(
	Renard::Curie::Model::View::Role::ForDocument
	Renard::Curie::Model::View::Role::Renderable
	Renard::Curie::Model::View::Role::Zoomable
	Renard::Curie::Model::View::Role::Pageable
	Renard::Curie::Model::View::Role::SubviewPageable
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Model::View::Grid - A view model for grid-based views

=head1 VERSION

version 0.004

=head1 EXTENDS

=over 4

=item * L<Renard::Curie::Model::View>

=back

=head1 CONSUMES

=over 4

=item * L<Renard::Curie::Model::View::Role::ForDocument>

=item * L<Renard::Curie::Model::View::Role::Pageable>

=item * L<Renard::Curie::Model::View::Role::Renderable>

=item * L<Renard::Curie::Model::View::Role::SubviewPageable>

=item * L<Renard::Curie::Model::View::Role::Zoomable>

=back

=head1 ATTRIBUTES

=head2 view_options

A L<Renard::Curie::Model::ViewOptions> that defines how the grid layout
will be constructed.

Predicate: L<has_view_options>

=head1 CLASS METHODS

=head2 FOREIGNBUILDARGS

  classmethod FOREIGNBUILDARGS(@)

Initialises the L<Glib::Object> super-class.

=head1 METHODS

=head2 has_view_options

A predicate for the C<view_options> attribute.

=head2 draw_page

See L<Renard::Curie::Model::View::Role::Renderable/draw_page>.

=head2 get_size_request

See L<Renard::Curie::Model::View::Role::Renderable/get_size_request>.

=head2 update_scroll_adjustment

  method update_scroll_adjustment($hadjustment, $vadjustment)

A callback used to set the C<GtkAdjustment> objects for the associated view.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
