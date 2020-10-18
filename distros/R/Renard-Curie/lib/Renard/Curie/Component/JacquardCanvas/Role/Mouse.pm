use Renard::Incunabula::Common::Setup;
package Renard::Curie::Component::JacquardCanvas::Role::Mouse;
# ABSTRACT: Mouse things for the canvas
$Renard::Curie::Component::JacquardCanvas::Role::Mouse::VERSION = '0.005';
use Role::Tiny;

use Glib qw(TRUE FALSE);
use Scalar::Util qw(refaddr);
use Intertangle::Yarn::Types qw(Point Size);

around new => sub {
	my $orig = shift;
	my $self = $orig->(@_);

	$self->signal_connect(
		'motion-notify-event' => sub { my $widget = shift; $widget->cb_on_motion_notify(@_) },
		$self
	);
	$self->signal_connect( 'button-press-event' => sub { my $widget = shift; $widget->cb_on_button_press_event(@_) }, $self );
	$self->signal_connect( 'button-release-event' => sub { my $widget = shift; $widget->cb_on_button_release_event(@_) }, $self );

	$self->add_events([qw/
		pointer-motion-mask
		button-press-mask
		button-release-mask
	/]);

	$self;
};

sub _get_data_for_pointer {
	my ($self, $event_point) = @_;

	state $last_point;
	state $data;

	my ($h, $v) = (
		$self->get_hadjustment,
		$self->get_vadjustment,
	);
	my $matrix = Intertangle::Yarn::Graphene::Matrix->new;
	$matrix->init_from_2d( 1, 0 , 0 , 1, $h->get_value, $v->get_value );

	my $point = $matrix * $event_point;

	if( defined $last_point && $last_point == $point ) {
		return $data;
	}

	my @intersects = map {
		$_->{bounds}->contains_point($point)
		? $_
		: ();
	} @{ $self->{views} };

	my @pages = map { $_->{page_number} } @intersects;

	$last_point = $point;

	$data = {
		intersects => \@intersects,
		pages => \@pages,
		point => $point,
	};

	return $data;
}

sub _get_text_data_for_pointer {
	my ($self, $pointer_data) = @_;

	state $last_pointer_data;
	state $text_data;

	if( defined $last_pointer_data && refaddr($last_pointer_data) == refaddr($pointer_data) ) {
		return $text_data;
	} else {
		$text_data = undef;
	}

	my @intersects = @{ $pointer_data->{intersects} };
	my $point = $pointer_data->{point};

	if( @intersects ) {
		my $actor = $intersects[0]->{actor};
		my $matrix = $intersects[0]->{matrix};
		my $bounds = $intersects[0]->{bounds};

		my $test_point = $matrix->untransform_point( $point, $bounds );

		$text_data = $actor->text_at_point( $test_point );
		if( @$text_data ) {
			$_->{t_bbox} = ($matrix->inverse)[1]
				->untransform_bounds(
					$_->{bbox},
					$bounds
			) for @$text_data;
		}
	}

	return $text_data;
}

sub cb_on_button_press_event {
	my ($widget, $event, $self) = @_;
	# nop
	return TRUE;
}

sub cb_on_button_release_event {
	my ($widget, $event, $self) = @_;
	# nop
	return TRUE;
}

sub cb_on_motion_notify {
	my ($widget, $event, $self) = @_;

	if( $event->state & 'button1-mask' ) {
		$widget->cb_on_motion_notify_button1($event, $self);
	}
	if( ! $event->state ) {
		$widget->cb_on_motion_notify_hover($event, $self);
	}
}

sub cb_on_motion_notify_hover {
	my ($widget, $event, $self) = @_;
	my $event_point = Point->coerce([ $event->x, $event->y ]);
	my $pointer_data = $self->_get_data_for_pointer($event_point);
	my $text_data = $self->_get_text_data_for_pointer($pointer_data);

	$self->do_pointer_data( $event_point, $pointer_data, $text_data );

	return TRUE;
}

sub cb_on_motion_notify_button1 {
	my ($widget, $event, $self) = @_;
	# nop
	return TRUE;
}

sub do_pointer_data {
	my ($self, $event_point, $pointer_data, $text_data ) = @_;
	# nop
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::JacquardCanvas::Role::Mouse - Mouse things for the canvas

=head1 VERSION

version 0.005

=head1 METHODS

=head2 do_pointer_data

Abstract method that can be used by roles to receive pointer data.

=head1 CALLBACKS

=head2 cb_on_button_press_event

...

=head2 cb_on_button_release_event

...

=head2 cb_on_motion_notify

...

=head2 cb_on_motion_notify_hover

...

=head2 cb_on_motion_notify_button1

...

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
