use Renard::Curie::Setup;
package Renard::Curie::Component::PageDrawingArea;
# ABSTRACT: Component that implements document page navigation
$Renard::Curie::Component::PageDrawingArea::VERSION = '0.001';
use Moo;
use Glib 'TRUE', 'FALSE';
use Glib::Object::Subclass 'Gtk3::Bin';
use Renard::Curie::Types qw(RenderableDocumentModel RenderablePageModel
	PageNumber Bool InstanceOf);
use Function::Parameters;

has document => (
	is => 'rw',
	isa => (RenderableDocumentModel),
	required => 1
);

has current_rendered_page => (
	is => 'rw',
	isa => (RenderablePageModel),
);

has current_page_number => (
	is => 'rw',
	isa => PageNumber,
	default => 1,
	trigger => 1 # _trigger_current_page_number
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

method BUILD {
	# so that the widget can take input
	$self->set_can_focus( TRUE );

	$self->setup_button_events;
	$self->setup_text_entry_events;
	$self->setup_drawing_area;
	$self->setup_number_of_pages_label;
	$self->setup_keybindings;

	# add as child for this L<Gtk3::Bin>
	$self->add(
		$self->builder->get_object('page-drawing-component')
	);
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

fun on_clicked_button_first_cb($button, $self) {
	$self->set_current_page_to_first;
}

fun on_clicked_button_last_cb($button, $self) {
	$self->set_current_page_to_last;
}

fun on_clicked_button_forward_cb($button, $self) {
	$self->set_current_page_forward;
}

fun on_clicked_button_back_cb($button, $self) {
	$self->set_current_page_back;
}

method setup_text_entry_events() {
	$self->builder->get_object('page-number-entry')->signal_connect(
		activate => \&on_activate_page_number_entry_cb, $self );
}

method setup_drawing_area() {
	my $drawing_area = Gtk3::DrawingArea->new();
	$self->drawing_area( $drawing_area );
	$drawing_area->signal_connect( draw => fun (
			(InstanceOf['Gtk3::DrawingArea']) $widget,
			(InstanceOf['Cairo::Context']) $cr) {
		my $rp = $self->document->get_rendered_page(
			page_number => $self->current_page_number,
		);
		$self->current_rendered_page( $rp );
		$self->on_draw_page_cb( $cr );

		return TRUE;
	}, $self);

	my $scrolled_window = Gtk3::ScrolledWindow->new();
	$scrolled_window->set_hexpand(TRUE);
	$scrolled_window->set_vexpand(TRUE);

	$scrolled_window->add($drawing_area);
	$scrolled_window->set_policy( 'automatic', 'automatic');
	$self->scrolled_window($scrolled_window);

	my $vbox = $self->builder->get_object('page-drawing-component');
	$vbox->pack_start( $scrolled_window, TRUE, TRUE, 0);
}

method setup_number_of_pages_label() {
	$self->builder->get_object("number-of-pages-label")
		->set_text( $self->document->last_page_number );
}

method setup_keybindings() {
	$self->signal_connect( key_press_event => \&on_key_press_event_cb, $self );
}

fun on_key_press_event_cb($window, $event, $self) {
	if($event->keyval == Gtk3::Gdk::KEY_Page_Down){
		$self->set_current_page_forward;
	} elsif($event->keyval == Gtk3::Gdk::KEY_Page_Up){
		$self->set_current_page_back;
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

	my $img = $self->current_rendered_page->cairo_image_surface;

	$cr->set_source_surface($img, ($self->drawing_area->get_allocated_width -
		$self->current_rendered_page->width) / 2, 0);
	$cr->paint;

	$self->drawing_area->set_size_request(
		$self->current_rendered_page->width,
		$self->current_rendered_page->height );

	$self->builder->get_object('page-number-entry')
		->set_text($self->current_page_number);
}

method _trigger_current_page_number {
	$self->refresh_drawing_area;
}

fun on_activate_page_number_entry_cb( $entry, $self ) {
	my $text = $entry->get_text;
	if ($text =~ /^[0-9]+$/ and $text <= $self->document->last_page_number
			and $text >= $self->document->first_page_number) {
		$self->current_page_number( $text );
	}
}

method set_current_page_forward() {
	if( $self->can_move_to_next_page ) {
		$self->current_page_number( $self->current_page_number + 1 );
	}
}

method set_current_page_back() {
	if( $self->can_move_to_previous_page ) {
		$self->current_page_number( $self->current_page_number - 1 );
	}
}

method set_current_page_to_first() {
	$self->current_page_number( $self->document->first_page_number );
}

method set_current_page_to_last() {
	$self->current_page_number( $self->document->last_page_number );
}

method can_move_to_previous_page() :ReturnType(Bool) {
	$self->current_page_number > $self->document->first_page_number;
}

method can_move_to_next_page() :ReturnType(Bool) {
	$self->current_page_number < $self->document->last_page_number;
}

method set_navigation_buttons_sensitivity() {
	my $can_move_forward = $self->can_move_to_next_page;
	my $can_move_back = $self->can_move_to_previous_page;

	for my $button_name ( qw(button-last button-forward) ) {
		$self->builder->get_object($button_name)
			->set_sensitive($can_move_forward);
	}

	for my $button_name ( qw(button-first button-back) ) {
		$self->builder->get_object($button_name)
			->set_sensitive($can_move_back);
	}
}

with qw(
	Renard::Curie::Component::Role::FromBuilder
	Renard::Curie::Component::Role::UIFileFromPackageName
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::PageDrawingArea - Component that implements document page navigation

=head1 VERSION

version 0.001

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

=item * L<Renard::Curie::Component::Role::FromBuilder>

=item * L<Renard::Curie::Component::Role::UIFileFromPackageName>

=back

=head1 ATTRIBUTES

=head2 document

The L<RenderableDocumentModel|Renard:Curie::Types/RenderableDocumentModel> that
this component displays.

=head2 current_rendered_page

A L<RenderablePageModel|Renard:Curie::Types/RenderablePageModel> for the
current page.

=head2 current_page_number

A L<PageNumber|Renard:Curie::Types/PageNumber> for the current page being
drawn.

=head2 drawing_area

The L<Gtk3::DrawingArea> that is used to draw the document on.

=head2 scrolled_window

The L<Gtk3::ScrolledWindow> container for the L</drawing_area>.

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

=head2 refresh_drawing_area

  method refresh_drawing_area()

This forces the drawing area to redraw.

=head2 set_current_page_forward

  method set_current_page_forward()

Increments the current page number if possible.

=head2 set_current_page_back

  method set_current_page_back()

Decrements the current page number if possible.

=head2 set_current_page_to_first

  method set_current_page_to_first()

Sets the page number to the first page of the document.

=head2 set_current_page_to_last

  method set_current_page_to_last()

Sets the current page to the last page of the document.

=head2 can_move_to_previous_page

  method can_move_to_previous_page() :ReturnType(Bool)

Predicate to check if we can decrement the current page number.

=head2 can_move_to_next_page

  method can_move_to_next_page() :ReturnType(Bool)

Predicate to check if we can increment the current page number.

=head2 set_navigation_buttons_sensitivity

  set_navigation_buttons_sensitivity()

Enables and disables forward and back navigation buttons when at the end and
start of the document respectively.

=head1 CLASS METHODS

=head2 FOREIGNBUILDARGS

  classmethod FOREIGNBUILDARGS(@)

Initialises the L<Gtk3::Bin> super-class.

=head1 FUNCTIONS

=head2 increment_scroll

  fun increment_scroll( (InstanceOf['Gtk3::Adjustment']) $current )

Helper function that scrolls down by the scrollbar's step increment.

=head2 decrement_scroll

  fun decrement_scroll( (InstanceOf['Gtk3::Adjustment']) $current )

Helper function that scrolls up by the scrollbar's step increment.

=head1 CALLBACKS

=head2 on_clicked_button_first_cb

  fun on_clicked_button_first_cb($button, $self)

Callback for when the "First" button is pressed.
See L</set_current_page_to_first>.

=head2 on_clicked_button_last_cb

  fun on_clicked_button_last_cb($button, $self)

Callback for when the "Last" button is pressed.
See L</set_current_page_to_last>.

=head2 on_clicked_button_forward_cb

  fun on_clicked_button_forward_cb($button, $self)

Callback for when the "Forward" button is pressed.
See L</set_current_page_forward>.

=head2 on_clicked_button_back_cb

  fun on_clicked_button_back_cb($button, $self)

Callback for when the "Back" button is pressed.
See L</set_current_page_back>.

=head2 on_key_press_event_cb

  fun on_key_press_event_cb($window, $event, $self)

Callback that responds to specific key events and dispatches to the appropriate
handlers.

=head2 on_draw_page_cb

  method on_draw_page_cb( (InstanceOf['Cairo::Context']) $cr )

Callback that draws the current page on to the L</drawing_area>.

=head2 on_activate_page_number_entry_cb

  fun on_activate_page_number_entry_cb( $entry, $self )

Callback that is called when text has been entered into the page number entry.

=begin comment

=method _trigger_current_page_number

  method _trigger_current_page_number

Called whenever the L</current_page_number> is changed. This allows for telling
the component to retrieve the new page and redraw.

=end comment

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
