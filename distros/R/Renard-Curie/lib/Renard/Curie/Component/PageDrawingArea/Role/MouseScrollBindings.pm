use Renard::Incunabula::Common::Setup;
package Renard::Curie::Component::PageDrawingArea::Role::MouseScrollBindings;
# ABSTRACT: A role to setup the bindings for mouse wheel scrolling for a page drawing area
$Renard::Curie::Component::PageDrawingArea::Role::MouseScrollBindings::VERSION = '0.005';
use Moo::Role;

use Renard::Incunabula::Document::Types qw(ZoomLevel);
use List::AllUtils qw(max);

use constant MIN_ZOOM_LEVEL => 0.001;

after BUILD => method(@) {
	$self->setup_scroll_bindings;
};

method setup_scroll_bindings() {
	$self->scrolled_window->signal_connect(
		'scroll-event' => \&on_scroll_event_cb, $self );
}

callback on_scroll_event_cb($window, $event, $self) {
	my $zoom_level = $self->view->view_options->zoom_options->zoom_level;
	if ( $event->state == 'control-mask' && $event->direction eq 'smooth') {
		my ($delta_x, $delta_y) =  $event->get_scroll_deltas();
		if ( $delta_y < 0 ) { $self->view_manager->set_zoom_level( $self->compute_zoom_out($zoom_level)  ); }
		elsif ( $delta_y > 0 ) { $self->view_manager->set_zoom_level( $self->compute_zoom_in($zoom_level) ); }
		return 1;
	} elsif ( $event->state == 'control-mask' && $event->direction eq 'up' ) {
		$self->view_manager->set_zoom_level( $self->compute_zoom_in($zoom_level) );
		return 1;
	} elsif ( $event->state == 'control-mask' && $event->direction eq 'down' ) {
		$self->view_manager->set_zoom_level( $self->compute_zoom_out($zoom_level) );
		return 1;
	}
	return 0;
}

method compute_zoom_out( (ZoomLevel) $zoom_level, $amount = 0.05 ) {
	return max(MIN_ZOOM_LEVEL, $zoom_level - $amount);
}

method compute_zoom_in( (ZoomLevel) $zoom_level, $amount = 0.05 ) :ReturnType(ZoomLevel) {
	return $zoom_level + $amount;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::PageDrawingArea::Role::MouseScrollBindings - A role to setup the bindings for mouse wheel scrolling for a page drawing area

=head1 VERSION

version 0.005

=head1 ATTRIBUTES

=head2 MIN_ZOOM_LEVEL

A constant for the minimum zoom level possible so that the zoom level never
becomes negative.

=head1 METHODS

=head2 setup_scroll_bindings

  method setup_scroll_bindings()

Sets up the signals to capture scroll events on this component.

=head2 compute_zoom_out

  method compute_zoom_out( (ZoomLevel) $zoom_level, $amount = 0.05 )

Computes the new zoom level in order to zoom out.

=head2 compute_zoom_in

  method compute_zoom_in( (ZoomLevel) $zoom_level, $amount = 0.05 ) :ReturnType(ZoomLevel) {

Computes the new zoom level in order to zoom in.

=head1 CALLBACKS

=head2 on_scroll_event_cb

  callback on_scroll_event_cb($window, $event, $self)

Callback that responds to specific scroll events and dispatches the associated
handlers.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
