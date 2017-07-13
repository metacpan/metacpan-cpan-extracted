use Renard::Incunabula::Common::Setup;
package Renard::Curie::Component::PageDrawingArea;
# ABSTRACT: Component that implements document page navigation
$Renard::Curie::Component::PageDrawingArea::VERSION = '0.003';
use Moo;

use Renard::Incunabula::Frontend::Gtk3::Helper;
use Glib 'TRUE', 'FALSE';
use Glib::Object::Subclass
	'Gtk3::Bin',
	signals => {
		'update-scroll-adjustment' => {},
	},
	;
use Renard::Incunabula::Common::Types qw(RenderableDocumentModel RenderablePageModel
	PageNumber ZoomLevel Bool InstanceOf);

has view_manager => (
	is => 'ro',
	required => 1,
	isa => InstanceOf['Renard::Curie::ViewModel::ViewManager'],
	handles => {
		view => current_view =>,
	},
);

has drawing_area => (
	is => 'rw',
	isa => InstanceOf['Gtk3::DrawingArea'],
);

has scrolled_window => (
	is => 'rw',
	isa => InstanceOf['Gtk3::ScrolledWindow'],
);


classmethod FOREIGNBUILDARGS(@) {
	return ();
}

method BUILD(@) {
	$self->signal_connect( 'update-scroll-adjustment', sub {
		if( $self->view->can('update_scroll_adjustment') ) {
			$self->view->update_scroll_adjustment(
				$self->scrolled_window->get_hadjustment,
				$self->scrolled_window->get_vadjustment,
			);
		}
	});
	$self->set_can_focus( TRUE );

	$self->setup_button_events;
	$self->setup_text_entry_events;
	$self->setup_drawing_area;
	$self->setup_number_of_pages_label;
	$self->setup_keybindings;
	$self->setup_scroll_bindings;

	# add as child for this L<Gtk3::Bin>
	$self->add(
		$self->builder->get_object('page-drawing-component')
	);

	$self->view_manager->signal_connect(
		'update-view' => fun( $view_manager, $view ) {
			$self->update_view( $view );
		}
	);
	$self->update_view( $self->view_manager->current_view );
	$self->view->signal_emit('view-changed');
}

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

method setup_text_entry_events() {
	$self->builder->get_object('page-number-entry')->signal_connect(
		activate => \&on_activate_page_number_entry_cb, $self );
}

method setup_drawing_area() {
	my $drawing_area = Gtk3::DrawingArea->new();
	$self->drawing_area( $drawing_area );
	$drawing_area->signal_connect( draw => callback(
			(InstanceOf['Gtk3::DrawingArea']) $widget,
			(InstanceOf['Cairo::Context']) $cr) {
		$self->on_draw_page_cb( $cr );

		return TRUE;
	}, $self);

	my $scrolled_window = Gtk3::ScrolledWindow->new();
	$scrolled_window->set_hexpand(TRUE);
	$scrolled_window->set_vexpand(TRUE);

	$scrolled_window->add($drawing_area);
	$scrolled_window->set_policy( 'automatic', 'automatic');
	$self->scrolled_window($scrolled_window);

	my @adjustments = (
		$self->scrolled_window->get_hadjustment,
		$self->scrolled_window->get_vadjustment,
	);
	my $callback = fun($adjustment) {
		$self->signal_emit('update-scroll-adjustment');
	};
	for my $adjustment (@adjustments) {
		$adjustment->signal_connect( 'value-changed' => $callback );
		$adjustment->signal_connect( 'changed' => $callback );
	}

	my $vbox = $self->builder->get_object('page-drawing-component');
	$vbox->pack_start( $scrolled_window, TRUE, TRUE, 0);
}

method setup_number_of_pages_label() {
	$self->builder->get_object("number-of-pages-label")
		->set_text( $self->view->document->number_of_pages );
}

method setup_keybindings() {
	$self->signal_connect( key_press_event => \&on_key_press_event_cb, $self );
}

callback on_key_press_event_cb($window, $event, $self) {
	if($event->keyval == Gtk3::Gdk::KEY_Page_Down){
		$self->view->set_current_page_forward;
	} elsif($event->keyval == Gtk3::Gdk::KEY_Page_Up){
		$self->view->set_current_page_back;
	} elsif($event->keyval == Gtk3::Gdk::KEY_Up){
		decrement_scroll($self->scrolled_window->get_vadjustment);
	} elsif($event->keyval == Gtk3::Gdk::KEY_Down){
		increment_scroll($self->scrolled_window->get_vadjustment);
	} elsif($event->keyval == Gtk3::Gdk::KEY_Right){
		increment_scroll($self->scrolled_window->get_hadjustment);
	} elsif($event->keyval == Gtk3::Gdk::KEY_Left){
		decrement_scroll($self->scrolled_window->get_hadjustment);
	}
}

method setup_scroll_bindings() {
	$self->scrolled_window->signal_connect(
		'scroll-event' => \&on_scroll_event_cb, $self );
}

callback on_scroll_event_cb($window, $event, $self) {
	if ( $event->state == 'control-mask' && $event->direction eq 'smooth') {
		my ($delta_x, $delta_y) =  $event->get_scroll_deltas();
		if ( $delta_y < 0 ) { $self->view_manager->set_zoom_level( $self->view->zoom_level - .05 ); }
		elsif ( $delta_y > 0 ) { $self->view_manager->set_zoom_level( $self->view->zoom_level + .05 ); }
		return 1;
	} elsif ( $event->state == 'control-mask' && $event->direction eq 'up' ) {
		$self->view_manager->set_zoom_level( $self->view->zoom_level + .05 );
		return 1;
	} elsif ( $event->state == 'control-mask' && $event->direction eq 'down' ) {
		$self->view_manager->set_zoom_level( $self->view->zoom_level - .05 );
		return 1;
	}
	return 0;
}

fun increment_scroll( (InstanceOf['Gtk3::Adjustment']) $current ) {
	my $adjustment = $current->get_value + $current->get_step_increment;
	$current->set_value($adjustment);
}

fun decrement_scroll( (InstanceOf['Gtk3::Adjustment']) $current ) {
	my $adjustment = $current->get_value - $current->get_step_increment;
	$current->set_value($adjustment);
}

method refresh_drawing_area() {
	return unless $self->drawing_area;

	$self->drawing_area->queue_draw;
}

method on_draw_page_cb( (InstanceOf['Cairo::Context']) $cr ) {
	# NOTE: we may want to change the signature to match the other
	# callbacks with $self as the last argument.
	$self->set_navigation_buttons_sensitivity;

	$self->view->draw_page( $self->drawing_area, $cr );

	my $page_number = $self->view->page_number;
	if( $self->view->can('_first_page_in_viewport') ) {
		$page_number = $self->view->_first_page_in_viewport;
	}

	$self->builder->get_object('page-number-entry')
		->set_text($page_number);
}

callback on_activate_page_number_entry_cb( $entry, $self ) {
	my $text = $entry->get_text;
	if( $self->view->document->is_valid_page_number($text) ) {
		$self->view->page_number( $text );
	} else {
		Renard::Incunabula::Common::Error::User::InvalidPageNumber->throw({
			payload => {
				text => $text,
				range => [
					$self->view->document->first_page_number,
					$self->view->document->last_page_number
				],
			}
		});
	}
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

method update_view($new_view) {
	# so that the widget can take input
	$self->view->signal_connect( 'view-changed', sub {
		$self->signal_emit('update-scroll-adjustment');
		if( $self->view->can('get_size_request') ) {
			if( $self->drawing_area ) {
				$self->drawing_area->set_size_request(
					$self->view->get_size_request
				);
				$self->refresh_drawing_area;
			}
		} else {
			$self->refresh_drawing_area;
		}
	} );

	$self->view->signal_emit('view-changed');
}

with qw(
	Renard::Incunabula::Frontend::Gtk3::Component::Role::FromBuilder
	Renard::Incunabula::Frontend::Gtk3::Component::Role::UIFileFromPackageName
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::PageDrawingArea - Component that implements document page navigation

=head1 VERSION

version 0.003

=head1 EXTENDS

=over 4

=item * L<Glib::Object::Subclass>

=item * L<Moo::Object>

=item * L<Gtk3::Bin>

=item * L<Glib::Object::_Unregistered::AtkImplementorIface>

=item * L<Gtk3::Buildable>

=back

=head1 CONSUMES

=over 4

=item * L<Renard::Incunabula::Frontend::Gtk3::Component::Role::FromBuilder>

=item * L<Renard::Incunabula::Frontend::Gtk3::Component::Role::UIFileFromPackageName>

=back

=head1 FUNCTIONS

=head2 increment_scroll

  fun increment_scroll( (InstanceOf['Gtk3::Adjustment']) $current )

Helper function that scrolls down by the scrollbar's step increment.

=head2 decrement_scroll

  fun decrement_scroll( (InstanceOf['Gtk3::Adjustment']) $current )

Helper function that scrolls up by the scrollbar's step increment.

=head1 ATTRIBUTES

=head2 view_manager

The view manager model for this application.

=head2 drawing_area

The L<Gtk3::DrawingArea> that is used to draw the document on.

=head2 scrolled_window

The L<Gtk3::ScrolledWindow> container for the L</drawing_area>.

=head1 CLASS METHODS

=head2 FOREIGNBUILDARGS

  classmethod FOREIGNBUILDARGS(@)

Initialises the L<Gtk3::Bin> super-class.

=head1 METHODS

=head2 BUILD

  method BUILD

Initialises the component's contained widgets and signals.

=head2 setup_button_events

  method setup_button_events()

Sets up the signals for the navigational buttons.

=head2 setup_text_entry_events

  method setup_text_entry_events()

Sets up the signals for the text entry box so the user can enter in page
numbers.

=head2 setup_drawing_area

  method setup_drawing_area()

Sets up the L</drawing_area> so that it draws the current page.

=head2 setup_number_of_pages_label

  method setup_number_of_pages_label()

Sets up the label that shows the number of pages in the document.

=head2 setup_keybindings

  method setup_keybindings()

Sets up the signals to capture key presses on this component.

=head2 setup_scroll_bindings

  method setup_scroll_bindings()

Sets up the signals to capture scroll events on this component.

=head2 refresh_drawing_area

  method refresh_drawing_area()

This forces the drawing area to redraw.

=head2 set_navigation_buttons_sensitivity

  set_navigation_buttons_sensitivity()

Enables and disables forward and back navigation buttons when at the end and
start of the document respectively.

=head2 update_view

  method update_view($new_view)

Sets up the signals for a new view.

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

=head2 on_key_press_event_cb

  callback on_key_press_event_cb($window, $event, $self)

Callback that responds to specific key events and dispatches to the appropriate
handlers.

=head2 on_scroll_event_cb

  callback on_scroll_event_cb($window, $event, $self)

Callback that responds to specific scroll events and dispatches the associated
handlers.

=head2 on_draw_page_cb

  method on_draw_page_cb( (InstanceOf['Cairo::Context']) $cr )

Callback that draws the current page on to the L</drawing_area>.

=head2 on_activate_page_number_entry_cb

  callback on_activate_page_number_entry_cb( $entry, $self )

Callback that is called when text has been entered into the page number entry.

=head1 SIGNALS

=over 4

=item *

C<update-scroll-adjustment>: called when the widget has been horizontally or vertically scrolled

=back

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
