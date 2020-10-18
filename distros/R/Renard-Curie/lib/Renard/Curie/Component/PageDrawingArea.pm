use Renard::Incunabula::Common::Setup;
package Renard::Curie::Component::PageDrawingArea;
# ABSTRACT: Component that implements document page navigation
$Renard::Curie::Component::PageDrawingArea::VERSION = '0.005';
use Moo;

use Intertangle::API::Gtk3::Helper;
use Glib 'TRUE', 'FALSE';
use Glib::Object::Subclass
	'Gtk3::Bin',
	;
use Renard::Incunabula::Common::Types qw(Bool InstanceOf);
use Renard::Incunabula::Document::Types qw(PageNumber ZoomLevel);
use Renard::Block::Format::Cairo::Types qw(RenderableDocumentModel RenderablePageModel);

use Renard::Curie::Component::JacquardCanvas;
use Renard::Curie::Model::View::Scenegraph;

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
	$self->set_can_focus( TRUE );

	$self->setup_drawing_area;

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
}

method setup_drawing_area() {
	my $drawing_area = Renard::Curie::Component::JacquardCanvas->new(
		sg => Renard::Curie::Model::View::Scenegraph->new(
			view_manager => $self->view_manager,
			view => $self->view,
		)->graph,
		scale => $self->view_manager->view_options->zoom_options->zoom_level,
	);
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

	$drawing_area->add_events('scroll-mask');

	my $vbox = $self->builder->get_object('page-drawing-component');
	$vbox->pack_start( $scrolled_window, TRUE, TRUE, 0);
}

method refresh_drawing_area($view) {
	return unless $self->drawing_area;

	$self->drawing_area->set_data(
		sg => Renard::Curie::Model::View::Scenegraph->new(
			view_manager => $self->view_manager,
			view => $view,
		)->graph,
		scale => $self->view_manager->view_options->zoom_options->zoom_level,
	);

	$self->drawing_area->queue_draw;
}

method on_draw_page_cb( (InstanceOf['Cairo::Context']) $cr ) {
	# NOTE: we may want to change the signature to match the other
	# callbacks with $self as the last argument.
	$self->set_navigation_buttons_sensitivity;

	my $page_number = $self->view->page_number;
	my $placeholder_text = $page_number;
	if( $self->drawing_area->can('_first_page_in_viewport') ) {
		my @range = (
			$self->drawing_area->_first_page_in_viewport,
			$self->drawing_area->_last_page_in_viewport,
		);
		unless( $range[0] <= $page_number && $page_number <= $range[1] ) {
			$self->view->page_number( $range[0] );
		}
		$placeholder_text = $range[0] == $range[1] ? "$range[0]" : "$range[0] - $range[1]";
	}

	$self->builder->get_object('page-number-entry')
		->set_placeholder_text($placeholder_text);
}


method update_view($new_view) {
	$new_view->signal_connect(
		'scroll-to-page', fun( $view, $page_number ) {
			$self->drawing_area->scroll_to_page( $page_number );
		}
	);
	$self->refresh_drawing_area( $new_view );
}

with qw(
	Intertangle::API::Gtk3::Component::Role::FromBuilder
	Intertangle::API::Gtk3::Component::Role::UIFileFromPackageName

	Renard::Curie::Component::PageDrawingArea::Role::KeyBindings
	Renard::Curie::Component::PageDrawingArea::Role::MouseScrollBindings
	Renard::Curie::Component::PageDrawingArea::Role::NavigationButtons
	Renard::Curie::Component::PageDrawingArea::Role::PageEntry
	Renard::Curie::Component::PageDrawingArea::Role::PageLabel

	Renard::Curie::Component::PageDrawingArea::Role::HighlightCurrentSentence
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::PageDrawingArea - Component that implements document page navigation

=head1 VERSION

version 0.005

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

=item * L<Intertangle::API::Gtk3::Component::Role::FromBuilder>

=item * L<Intertangle::API::Gtk3::Component::Role::UIFileFromPackageName>

=item * L<Renard::Curie::Component::PageDrawingArea::Role::HighlightCurrentSentence>

=item * L<Renard::Curie::Component::PageDrawingArea::Role::KeyBindings>

=item * L<Renard::Curie::Component::PageDrawingArea::Role::MouseScrollBindings>

=item * L<Renard::Curie::Component::PageDrawingArea::Role::NavigationButtons>

=item * L<Renard::Curie::Component::PageDrawingArea::Role::PageEntry>

=item * L<Renard::Curie::Component::PageDrawingArea::Role::PageLabel>

=back

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

=head2 setup_drawing_area

  method setup_drawing_area()

Sets up the L</drawing_area> so that it draws the current page.

=head2 refresh_drawing_area

  method refresh_drawing_area()

This forces the drawing area to redraw.

=head2 update_view

  method update_view($new_view)

Sets up the signals for a new view.

=head1 CALLBACKS

=head2 on_draw_page_cb

  method on_draw_page_cb( (InstanceOf['Cairo::Context']) $cr )

Callback that draws the current page on to the L</drawing_area>.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
