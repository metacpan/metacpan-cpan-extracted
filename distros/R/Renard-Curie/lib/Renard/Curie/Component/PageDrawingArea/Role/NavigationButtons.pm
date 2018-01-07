use Renard::Incunabula::Common::Setup;
package Renard::Curie::Component::PageDrawingArea::Role::NavigationButtons;
# ABSTRACT: A role for the navigation buttons
$Renard::Curie::Component::PageDrawingArea::Role::NavigationButtons::VERSION = '0.004';
use Moo::Role;

after BUILD => method(@) {
	$self->setup_button_events;
};

method setup_button_events() {
	$self->builder->get_object('button-first')->signal_connect(
		clicked => \&on_clicked_button_first_cb, $self );
	$self->builder->get_object('button-last')->signal_connect(
		clicked => \&on_clicked_button_last_cb, $self );

	$self->builder->get_object('button-forward')->signal_connect(
		clicked => \&on_clicked_button_forward_cb, $self );
	$self->builder->get_object('button-back')->signal_connect(
		clicked => \&on_clicked_button_back_cb, $self );

	$self->set_navigation_buttons_sensitivity;
}

callback on_clicked_button_first_cb($button, $self) {
	$self->view->set_current_page_to_first;
}

callback on_clicked_button_last_cb($button, $self) {
	$self->view->set_current_page_to_last;
}

callback on_clicked_button_forward_cb($button, $self) {
	$self->view->set_current_page_forward;
}

callback on_clicked_button_back_cb($button, $self) {
	$self->view->set_current_page_back;
}

method set_navigation_buttons_sensitivity() {
	my $can_move_forward = $self->view->can_move_to_next_page;
	my $can_move_back = $self->view->can_move_to_previous_page;

	for my $button_name ( qw(button-last button-forward) ) {
		$self->builder->get_object($button_name)
			->set_sensitive($can_move_forward);
	}

	for my $button_name ( qw(button-first button-back) ) {
		$self->builder->get_object($button_name)
			->set_sensitive($can_move_back);
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::PageDrawingArea::Role::NavigationButtons - A role for the navigation buttons

=head1 VERSION

version 0.004

=head1 METHODS

=head2 setup_button_events

  method setup_button_events()

Sets up the signals for the navigational buttons.

=head2 set_navigation_buttons_sensitivity

  set_navigation_buttons_sensitivity()

Enables and disables forward and back navigation buttons when at the end and
start of the document respectively.

=head1 CALLBACKS

=head2 on_clicked_button_first_cb

  callback on_clicked_button_first_cb($button, $self)

Callback for when the "First" button is pressed.
See L</set_current_page_to_first>.

=head2 on_clicked_button_last_cb

  callback on_clicked_button_last_cb($button, $self)

Callback for when the "Last" button is pressed.
See L</set_current_page_to_last>.

=head2 on_clicked_button_forward_cb

  callback on_clicked_button_forward_cb($button, $self)

Callback for when the "Forward" button is pressed.
See L</set_current_page_forward>.

=head2 on_clicked_button_back_cb

  callback on_clicked_button_back_cb($button, $self)

Callback for when the "Back" button is pressed.
See L</set_current_page_back>.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
