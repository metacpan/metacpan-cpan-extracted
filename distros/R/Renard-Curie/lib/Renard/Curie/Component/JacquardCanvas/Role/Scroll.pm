use Renard::Incunabula::Common::Setup;
package Renard::Curie::Component::JacquardCanvas::Role::Scroll;
# ABSTRACT: Scroll role
$Renard::Curie::Component::JacquardCanvas::Role::Scroll::VERSION = '0.005';
use Role::Tiny;
use feature qw(current_sub);

use Object::Util magic => 0;
use Intertangle::Yarn::Types qw(Point Size);

use constant STEP_SIZE_RATIO => (1 / 20.0);

around new => sub {
	my $orig = shift;
	my $self = $orig->(@_);

	$self->signal_connect(
		realize => sub {
			$self->update_bounds;

			for my $adj (qw(get_hadjustment get_vadjustment)) {
				for my $sig (qw(changed value-changed)) {
					$self->$adj->signal_connect(
						$sig => \&cb_on_scroll, $self );
				}
			}
		}
	);

	$self->signal_connect(
		'size-allocate' => sub {
			my ($widget, $allocation) = @_;
			$self->get_hadjustment
				->set_page_size( $allocation->{width} );
			$self->get_vadjustment
				->set_page_size( $allocation->{height} );
		}
	);

	$self->add_events('scroll-mask');

	$self;
};

after set_data => sub {
	my ($self, %data) = @_;

	$self->update_bounds;
};

sub update_bounds {
	my ($self) = @_;
	my $bounds = $self->{sg}->bounds;

	return unless $self->get_realized;


	$_->freeze_notify for( $self->get_hadjustment, $self->get_vadjustment );

	$self->get_hadjustment
		->$_tap( set_lower => 0 )
		->$_tap( set_upper =>  $self->{scale} * $bounds->size->width)
		->$_tap( set_step_increment => ($self->get_hadjustment->get_page_size * STEP_SIZE_RATIO ) )
		;
	$self->get_vadjustment
		->$_tap( set_lower => 0 )
		->$_tap( set_upper => $self->{scale} * $bounds->size->height )
		->$_tap( set_step_increment => ($self->get_vadjustment->get_page_size * STEP_SIZE_RATIO ) )
		;

	$_->thaw_notify for( $self->get_hadjustment, $self->get_vadjustment );

	cb_on_scroll(undef, $self);
}

sub cb_on_scroll {
	my ($adjustment, $self) = @_;
	my ($h, $v) = (
		$self->get_hadjustment,
		$self->get_vadjustment,
	);

	my $vp_origin = Point->coerce([ $h->get_value, $v->get_value ]);
	my $vp_size = Size->coerce([ $h->get_page_size, $v->get_page_size ]);

	my $vp_bounds = Intertangle::Yarn::Graphene::Rect->new(
		origin => $vp_origin,
		size => $vp_size,
	);

	my @views;
	my $vp_is_visible = sub {
		my ($g, $g_matrix) = @_;
		my $t_matrix = Intertangle::Yarn::Graphene::Matrix->new;
		if( $g->does('Intertangle::Jacquard::Role::Render::QnD::Layout') ) {
			$t_matrix->init_from_2d( 1, 0 , 0 , 1, $g->x->value, $g->y->value );
		} else {
			# position translation is already incorporated into bounds of non-layout
			$t_matrix->init_from_2d( 1, 0 , 0 , 1, 0, 0 );
		}
		my $matrix = $t_matrix x $g_matrix;
		if( $g->isa('Renard::Curie::Model::View::Grid::PageActor') &&
			( (my $t_bounds = $matrix->transform_bounds($g->bounds))->intersection($vp_bounds) )[0]
		) {
			$g->{visible} = 1;
			push @views, {
				page_number => $g->page_number,
				actor => $g,
				bounds => $t_bounds,
				matrix => $matrix,
				g_matrix => $g_matrix,
				t_matrix => $t_matrix,
			};
		}
		__SUB__->($_, $matrix) for @{ $g->children };
	};

	my $matrix = Intertangle::Yarn::Graphene::Matrix->new;
	$matrix->init_scale($self->{scale}, $self->{scale}, 1);
	$vp_is_visible->($self->{sg}, $matrix);

	$self->{views} = \@views;

	$self->signal_emit( 'view-changed' );
}

sub _first_page_in_viewport {
	my ($self) = @_;
	$self->{views}[0]{page_number};
}

sub _last_page_in_viewport {
	my ($self) = @_;
	$self->{views}[-1]{page_number};
}

sub scroll_to_page {
	my ($self, $page_number) = @_;

	my $page_actor = $self->{pages}{$page_number};
	my $origin = $page_actor->origin_point;

	my $actor = $page_actor;
	my $matrix = Intertangle::Yarn::Graphene::Matrix->new;
	$matrix->init_identity;
	do {
		my $g = $actor;
		my $t_matrix = Intertangle::Yarn::Graphene::Matrix->new;
		if( $g->does('Intertangle::Jacquard::Role::Render::QnD::Layout') ) {
			$t_matrix->init_from_2d( 1, 0 , 0 , 1, $g->x->value, $g->y->value );
		} else {
			# position translation is already incorporated into bounds of non-layout
			$t_matrix->init_from_2d( 1, 0 , 0 , 1, 0, 0 );
		}
		my $info = { g => $g, m => $t_matrix };
		$matrix = $matrix x $t_matrix;

		$actor = $actor->parent;
	} while( $actor );

	my $scale_matrix = Intertangle::Yarn::Graphene::Matrix->new;
	$scale_matrix->init_scale($self->{scale}, $self->{scale}, 1);

	$matrix = $matrix x $scale_matrix;

	my $point = $matrix * $origin;

	my ($h, $v) = (
		$self->get_hadjustment,
		$self->get_vadjustment,
	);

	$_->freeze_notify for( $h, $v );
	$h->set_value( $point->x );
	$v->set_value( $point->y );
	$_->thaw_notify for( $h, $v );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::JacquardCanvas::Role::Scroll - Scroll role

=head1 VERSION

version 0.005

=head1 ATTRIBUTES

=head2 STEP_SIZE_RATIO

Ratio of the viewport page size to the viewport step size.

=head1 METHODS

=head2 update_bounds

Update the viewport adjustments to the scene graph size.

=head2 scroll_to_page

Scroll the view port to a given page number.

=head1 CALLBACKS

=head2 cb_on_scroll

Callback for any changes to the scroll adjustments.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
