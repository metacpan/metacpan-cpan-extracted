use Renard::Incunabula::Common::Setup;
package Renard::Curie::Component::JacquardCanvas;
# ABSTRACT: Canvas component
$Renard::Curie::Component::JacquardCanvas::VERSION = '0.005';
use Role::Tiny::With;

use Intertangle::API::Gtk3::Helper;
use Glib qw(TRUE FALSE);

use feature qw(current_sub);

use Glib::Object::Subclass
	'Gtk3::DrawingArea',
	interfaces => [ 'Gtk3::Scrollable', ],
	properties => [
		# Gtk3::Scrollable interface
		Glib::ParamSpec->object ('hadjustment','hadj','', Gtk3::Adjustment::, [qw/readable writable construct/] ),
		Glib::ParamSpec->object ('vadjustment','vadj','', Gtk3::Adjustment::, [qw/readable writable construct/] ),
		Glib::ParamSpec->enum   ('hscroll-policy','hpol','', "Gtk3::ScrollablePolicy", "GTK_SCROLL_MINIMUM", [qw/readable writable/]),
		Glib::ParamSpec->enum   ('vscroll-policy','vpol','', "Gtk3::ScrollablePolicy", "GTK_SCROLL_MINIMUM", [qw/readable writable/]),
	],
	signals => {
		'view-changed' => {},
		'text-found' => {},
		'text-selected' => {
			param_types => [
				'Glib::Scalar', # selection hash
			]
		},
	},
;

use Glib qw(TRUE FALSE);
use List::AllUtils qw(first);

use Intertangle::Yarn::Types qw(Point Size);

my $_EmptyGraph = Moo::Role->create_class_with_roles(
	'Intertangle::Jacquard::Actor' => qw(
	Intertangle::Jacquard::Role::Geometry::Position2D
	Intertangle::Jacquard::Role::Geometry::Size2D
	Intertangle::Jacquard::Role::Render::QnD::Cairo::Group
	Intertangle::Jacquard::Role::Render::QnD::Size::Direct
	Intertangle::Jacquard::Role::Render::QnD::Bounds::Direct
));

use constant HIGHLIGHT_BOUNDS => $ENV{T_GRID_HIGHLIGHT_BOUNDS} // 0;
use constant HIGHLIGHT_LAYERS => $ENV{T_GRID_HIGHLIGHT_LAYERS} // 0;

sub new {
	my ($class, %args) = @_;

	my $self = $class->SUPER::new();

	$self->set_data(%args);

	$self->signal_connect( draw => \&cb_on_draw );

	$self;
}

sub set_data {
	my ($self, %data) = @_;

	$self->{sg} = $data{sg} // $_EmptyGraph->new;
	$self->{scale} = $data{scale} // 1.0;

	my %page_map;
	my $map_pages = sub {
		my ($g) = @_;
		if( $g->isa('Renard::Curie::Model::View::Grid::PageActor' ) ) {
			$page_map{ $g->page_number} = $g;
		}
		__SUB__->($_) for @{ $g->children };
	};
	$map_pages->($self->{sg});
	$self->{pages} = \%page_map;

	if( exists $data{page_number} ) {
		$self->scroll_to_page( $data{page_number} );
	}

}

sub cb_on_draw {
	my ($self, $cr) = @_;

	$cr->save;

	my ($h, $v) = (
		$self->get_hadjustment,
		$self->get_vadjustment,
	);

	$cr->translate( -$h->get_value, -$v->get_value );

	$cr->scale($self->{scale}, $self->{scale});

	$cr->set_source_rgb(0, 0, 0);
	$cr->paint;

	$self->{sg}->render_cairo( $cr );

	$cr->restore;

	if( $self->{selection}{state} ) {
		my $start_pages = $self->{selection}{start}{pointer}{pages};
		my $end_pages = $self->{selection}{end}{pointer}{pages};
		if( @$start_pages && @$end_pages ) {
			my @sorted = sort {$a <=> $b} ( $start_pages->[0] , $end_pages->[0] );
			my @pgs = ( $sorted[0] .. $sorted[1] );
			my @bboxes;
			for my $page_number (@pgs) {
				my ($page, $view) = $self->_get_page_view_for_page_number($page_number);
				next unless $view;

				my @extents = $page->get_extents_from_selection(
					$self->{selection}{start},
					$self->{selection}{end}
				);

				push @bboxes, @{
					$self->_get_bboxes_for_page_extents(
						$page, $view, \@extents )
				};
			}
			for my $bounds (@bboxes) {
				$self->_draw_bounds_as_rectangle($cr, $bounds);
				$cr->set_source_rgba(0, 0, 1, 0.2);
				$cr->fill;
			}
		}
	}


	if( HIGHLIGHT_LAYERS() && exists $self->{text} ) {
		for my $layer (@{ $self->{text}{layers} }) {
			my $bounds = $layer->{t_bbox};
			$self->_draw_bounds_as_rectangle($cr, $bounds);
			$cr->set_source_rgba(0, 0, 0, 0.5);
			$cr->set_line_width(1);
			$cr->stroke_preserve;
			$cr->set_source_rgba(1, 0.5, 0.5, 0.2);
			$cr->fill;
		}
	}

	if( HIGHLIGHT_BOUNDS() ) {
		#say "Drawing # of bounds: @{[ scalar @{ $self->{views} } ]}";
		for my $bounds (map { $_->{bounds} } @{ $self->{views} }) {
			$self->_draw_bounds_as_rectangle($cr, $bounds);
			$cr->set_source_rgba(1, 0, 0, 0.2);
			$cr->fill;
		}
	}
}

sub _get_page_view_for_page_number {
	my ($self, $page_number) = @_;
	my $page = $self->{pages}{$page_number};
	my $view = first { $_->{page_number} == $page_number } @{ $self->{views} };
	( $page, $view );
}

sub _get_bboxes_for_page_extents {
	my ($self, $page, $view, $extents) = @_;

	my @bboxes;

	my $matrix = $view->{matrix};
	my $bounds = $view->{bounds};
	if( @$extents ) {
		my @page_bboxes = $page->get_bboxes_from_extents(@$extents);
		push @bboxes, ($matrix->inverse)[1]
			->untransform_bounds(
				$_,
				$bounds
		) for @page_bboxes;
	}

	\@bboxes;
}

sub _draw_bounds_as_rectangle {
	my ($self, $cr, $bounds) = @_;

	my ($h, $v) = (
		$self->get_hadjustment,
		$self->get_vadjustment,
	);

	$cr->rectangle(
		$bounds->get_x - $h->get_value,
		$bounds->get_y - $v->get_value,
		$bounds->get_width,
		$bounds->get_height,
	);
}

sub GET_BORDER { (FALSE, undef); }

with qw(
	Renard::Curie::Component::JacquardCanvas::Role::Mouse
	Renard::Curie::Component::JacquardCanvas::Role::MouseCursor
	Renard::Curie::Component::JacquardCanvas::Role::MouseSelection
	Renard::Curie::Component::JacquardCanvas::Role::MousePageTooltip
	Renard::Curie::Component::JacquardCanvas::Role::Scroll
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::JacquardCanvas - Canvas component

=head1 VERSION

version 0.005

=head1 EXTENDS

=over 4

=item * L<Glib::Object::Subclass>

=item * L<Gtk3::Scrollable>

=item * L<Gtk3::DrawingArea>

=item * L<Glib::Object::_Unregistered::AtkImplementorIface>

=item * L<Gtk3::Buildable>

=back

=head1 FUNCTIONS

=head2 HIGHLIGHT_BOUNDS HIGHLIGHT_LAYERS

Debug environment variables.

=head1 METHODS

=head2 GET_BORDER

Implements C<Gtk3::Scrollable::get_border>.

=head1 CALLBACKS

=head2 cb_on_draw

Callback for C<draw> signal.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
