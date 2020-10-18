use Renard::Incunabula::Common::Setup;
package Renard::Curie::Model::View::Grid::PageActor;
# ABSTRACT: A jacquard actor for a document page
$Renard::Curie::Model::View::Grid::PageActor::VERSION = '0.005';
use Mu;
use Renard::Block::Format::Cairo::Types qw(RenderableDocumentModel);
use Intertangle::Taffeta::Graphics::Image::PNG;
use Intertangle::Taffeta::Graphics::Image::CairoImageSurface;
use Intertangle::Yarn::Graphene;
use Intertangle::Yarn::Types qw(Point Size);
use List::AllUtils qw(pairmap);

extends qw(Intertangle::Jacquard::Actor);

ro document => (
	isa => RenderableDocumentModel,
);

ro 'page_number';


lazy _rendered_page => method() {
	$self->document->get_rendered_page(
		page_number => $self->page_number,
	);
};

lazy height => method() { $self->_rendered_page->height };
lazy width => method() { $self->_rendered_page->width };

lazy _taffeta => method() {
	my $rp = $self->_rendered_page;
	my $taffeta;
	if( $rp->can('png_data') ) {
		$taffeta = Intertangle::Taffeta::Graphics::Image::PNG->new(
			data => $rp->png_data,
			origin => $self->origin_point,
		);
	} else {
		$taffeta = Intertangle::Taffeta::Graphics::Image::CairoImageSurface->new(
			cairo_image_surface => $rp->cairo_image_surface,
			origin => $self->origin_point,
		);
	}

	$taffeta;
};

method render($svg) {
	$self->_taffeta->render_svg( $svg );
}

method render_cairo($cr) {
	return unless $self->{visible};
	$self->_taffeta->render_cairo( $cr );
}

lazy _textual_page => method() {
	my $tp = $self->document->get_textual_page(
		$self->page_number,
	);

	$tp;
};

lazy _page_transform => method() {
	my $page_transform = Intertangle::Yarn::Graphene::Matrix->new;
	$page_transform->init_from_2d( 1, 0 , 0 , 1,
		$self->x->value,
		$self->y->value );
	$page_transform;
};

method _bbox_to_rect($bbox) {
	my ($x0, $y0, $x1, $y1) = split ' ', $bbox;
	$self->_page_transform->transform_bounds(
		Intertangle::Yarn::Graphene::Rect->new(
			origin => Point->coerce([$x0, $y0]),
			size => Size->coerce([$x1-$x0, $y1-$y0]),
		)
	);
}

method _m_quad_to_rect($quad) {
	my @points = pairmap { Point->coerce([$a, $b]) } split ' ', $quad;
	$self->_page_transform->transform_bounds(
		Intertangle::Yarn::Graphene::Quad->alloc
			->init_from_points( \@points )
			->bounds
	);
}

method _compute_bbox_for_tag_value($tag_value) {
	if( exists $tag_value->{g_bbox} ) {
		return $tag_value->{g_bbox};
	}
	return $tag_value->{g_bbox} = exists $tag_value->{bbox}
		? $self->_bbox_to_rect($tag_value->{bbox})
		: $self->_m_quad_to_rect($tag_value->{quad});
}

method get_bboxes_from_extents( $start_extent, $end_extent ) {
	my @gather_bboxes;
	my @gather_line_extents;
	my $tp = $self->_textual_page;

	return $self->get_bboxes_from_extents($end_extent, $start_extent)
		if $start_extent > $end_extent;

	my $inside_extent = sub {
		my ($extent) = @_;
		$start_extent <= $extent->start && $extent->end <= $end_extent
	};

	$tp->iter_extents( sub {
			my ($extent, $tag_name, $tag_value) = @_;
			if( $tag_name eq 'line' && $inside_extent->($extent)
				|| (
					$tag_name eq 'char'
					&& ! $inside_extent->($tp->get_tag_extent( $extent->start, 'line'))
				)
			) {
				my $g_bbox = $self->_compute_bbox_for_tag_value($tag_value);
				push @gather_bboxes, $g_bbox;
			}
		},
		only => ['line', 'char'],
		start => $start_extent,
		end => $end_extent,
	);

	return @gather_bboxes;
}

method get_extents_from_selection( $start, $end ) {
	my $pg = $self->page_number;
	my $start_page = $start->{pointer}{pages}[0];
	my $end_page = $end->{pointer}{pages}[0];

	return $self->get_extents_from_selection($end, $start)
		if $start_page > $end_page;

	my $tp = $self->_textual_page;

	my $get_test_point = sub {
		my ($selection) = @_;

		my $pointer_data = $selection->{pointer};

		my @intersects = @{ $pointer_data->{intersects} };
		my $point = $pointer_data->{point};

		my $matrix = $intersects[0]->{matrix};
		my $bounds = $intersects[0]->{bounds};

		my $test_point = $matrix->untransform_point( $point, $bounds );

		return $test_point;
	};

	if( $start_page == $pg
		&&  $end_page == $pg ) {
		my $start_data = $self->text_at_point( $get_test_point->( $start ) );
		return unless
			defined $start_data
			&& @$start_data
			&& $start_data->[-1]{tag} eq 'char';
		my $end_data = $self->text_at_point( $get_test_point->( $end ) );
		return unless
			defined $end_data
			&& @$end_data
			&& $end_data->[-1]{tag} eq 'char';
		return ( $start_data->[-1]{extent}->start,
			$end_data->[-1]{extent}->end );
	} elsif( $start_page == $pg ) {
		my $start_data = $self->text_at_point( $get_test_point->( $start ) );
		return unless
			defined $start_data
			&& @$start_data
			&& $start_data->[-1]{tag} eq 'char';
		return ($start_data->[-1]{extent}->start, $tp->length);
	} elsif( $end_page == $pg ) {
		my $end_data = $self->text_at_point( $get_test_point->( $end ) );
		return unless
			defined $end_data
			&& @$end_data
			&& $end_data->[-1]{tag} eq 'char';
		return (0, $end_data->[-1]{extent}->end )
	} elsif( $start_page < $pg && $pg < $end_page ) {
		# get all the lines for the page
		return (0, $tp->length);
	}
}

method text_at_point( (Point) $point) {
	my $tp = $self->_textual_page;

	my @all_levels;

	my @subpage_level_names = qw(block line char);
	my @current_extents = ( 0, $tp->length );
	for my $level_idx (0..@subpage_level_names-1) {
		my $level = $subpage_level_names[$level_idx];
		my @gather;
		$tp->iter_extents( sub {
				my ($extent, $tag_name, $tag_value) = @_;
				my $g_bbox = $self->_compute_bbox_for_tag_value($tag_value);
				push @gather, {
					extent => $extent,
					tag => $tag_name,
					bbox => $g_bbox,
				} if $g_bbox->contains_point( $point );
			},
			only => [$level],
			start => $current_extents[0],
			end => $current_extents[1],
		);

		if( @gather ) {
			$all_levels[$level_idx] = $gather[0];
			my $extent = $gather[0]->{extent};
			@current_extents = ( $extent->start, $extent->end );
		} else {
			last;
		}
	}

	return \@all_levels;
}

with qw(
	Intertangle::Jacquard::Role::Render::QnD::SVG
	Intertangle::Jacquard::Role::Render::QnD::Cairo
	Intertangle::Jacquard::Role::Geometry::Position2D
	Intertangle::Jacquard::Role::Render::QnD::Size::Direct
	Intertangle::Jacquard::Role::Render::QnD::Bounds::Direct
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Model::View::Grid::PageActor - A jacquard actor for a document page

=head1 VERSION

version 0.005

=head1 EXTENDS

=over 4

=item * L<Intertangle::Jacquard::Actor>

=back

=head1 CONSUMES

=over 4

=item * L<Intertangle::Jacquard::Role::Geometry::Position2D>

=item * L<Intertangle::Jacquard::Role::Render::QnD::Bounds::Direct>

=item * L<Intertangle::Jacquard::Role::Render::QnD::Cairo>

=item * L<Intertangle::Jacquard::Role::Render::QnD::SVG>

=item * L<Intertangle::Jacquard::Role::Render::QnD::Size::Direct>

=back

=head1 ATTRIBUTES

=head2 document

A C<RenderableDocumentModel> (required).

=head2 page_number

The page number of C<document> to render.

=head1 METHODS

=head2 render

Render to SVG.

=head2 render_cairo

Render to Cairo.

=head2 get_bboxes_from_extents

Return Array of bounding boxes from extents of the page text.

=head2 get_extents_from_selection

Return extents on the page text given (start, end) pointer locations.

=head2 text_at_point

Return (block, line, char) for page text under a given point.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
