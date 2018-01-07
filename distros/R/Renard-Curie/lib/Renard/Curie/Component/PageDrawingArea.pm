use Renard::Incunabula::Common::Setup;
package Renard::Curie::Component::PageDrawingArea;
# ABSTRACT: Component that implements document page navigation
$Renard::Curie::Component::PageDrawingArea::VERSION = '0.004';
use Moo;

use Renard::Incunabula::Frontend::Gtk3::Helper;
use Glib 'TRUE', 'FALSE';
use Glib::Object::Subclass
	'Gtk3::Bin',
	signals => {
		'update-scroll-adjustment' => {},
	},
	;
use Renard::Incunabula::Common::Types qw(Bool InstanceOf);
use Renard::Incunabula::Document::Types qw(PageNumber ZoomLevel);
use Renard::Incunabula::Format::Cairo::Types qw(RenderableDocumentModel RenderablePageModel);

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
	$self->view->signal_emit('view-changed');
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

	Renard::Curie::Component::PageDrawingArea::Role::KeyBindings
	Renard::Curie::Component::PageDrawingArea::Role::MouseScrollBindings
	Renard::Curie::Component::PageDrawingArea::Role::NavigationButtons
	Renard::Curie::Component::PageDrawingArea::Role::PageEntry
	Renard::Curie::Component::PageDrawingArea::Role::PageLabel
	Renard::Curie::Component::PageDrawingArea::Role::ScrollWindow
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::PageDrawingArea - Component that implements document page navigation

=head1 VERSION

version 0.004

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

=item * L<Renard::Curie::Component::PageDrawingArea::Role::KeyBindings>

=item * L<Renard::Curie::Component::PageDrawingArea::Role::MouseScrollBindings>

=item * L<Renard::Curie::Component::PageDrawingArea::Role::NavigationButtons>

=item * L<Renard::Curie::Component::PageDrawingArea::Role::PageEntry>

=item * L<Renard::Curie::Component::PageDrawingArea::Role::PageLabel>

=item * L<Renard::Curie::Component::PageDrawingArea::Role::ScrollWindow>

=item * L<Renard::Incunabula::Frontend::Gtk3::Component::Role::FromBuilder>

=item * L<Renard::Incunabula::Frontend::Gtk3::Component::Role::UIFileFromPackageName>

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
