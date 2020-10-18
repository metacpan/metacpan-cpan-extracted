use Renard::Incunabula::Common::Setup;
package Renard::Curie::Component::PageDrawingArea::Role::KeyBindings;
# ABSTRACT: A role to setup the key bindings for a page drawing area
$Renard::Curie::Component::PageDrawingArea::Role::KeyBindings::VERSION = '0.005';
use Moo::Role;
use Gtk3;

after BUILD => method(@) {
	$self->setup_keybindings;
};

method setup_keybindings() {
	$self->signal_connect( key_press_event => \&on_key_press_event_cb, $self );
}

callback on_key_press_event_cb($window, $event, $self) {
	if($event->keyval == Gtk3::Gdk::KEY_Page_Down){
		$self->view->set_current_page_forward;
	} elsif($event->keyval == Gtk3::Gdk::KEY_Page_Up){
		$self->view->set_current_page_back;
	} elsif($event->keyval == Gtk3::Gdk::KEY_Up){
		$self->scrolled_window->get_vadjustment->decrement_step;
	} elsif($event->keyval == Gtk3::Gdk::KEY_Down){
		$self->scrolled_window->get_vadjustment->increment_step;
	} elsif($event->keyval == Gtk3::Gdk::KEY_Right){
		$self->scrolled_window->get_hadjustment->increment_step;
	} elsif($event->keyval == Gtk3::Gdk::KEY_Left){
		$self->scrolled_window->get_hadjustment->decrement_step;
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::PageDrawingArea::Role::KeyBindings - A role to setup the key bindings for a page drawing area

=head1 VERSION

version 0.005

=head1 METHODS

=head2 setup_keybindings

  method setup_keybindings()

Sets up the signals to capture key presses on this component.

=head1 CALLBACKS

=head2 on_key_press_event_cb

  callback on_key_press_event_cb($window, $event, $self)

Callback that responds to specific key events and dispatches to the appropriate
handlers.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
