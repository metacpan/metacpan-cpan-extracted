use Renard::Incunabula::Common::Setup;
package Renard::Curie::Component::MainWindow;
# ABSTRACT: Main window of the application
$Renard::Curie::Component::MainWindow::VERSION = '0.005';
use Intertangle::API::Gtk3::Helper;

use Gtk3;
use Cairo;
use Glib::Object::Introspection;
use Glib 'TRUE', 'FALSE';

use Moo 2.001001;

use MooX::Role::Logger ();
use MooX::ShortHas;

use Renard::Incunabula::Common::Types qw(InstanceOf Path Str);
use Renard::Incunabula::Document::Types qw(DocumentModel);

use IO::Async::Loop::Glib;

has loop => ( is => 'lazy' );

sub _build_loop {
	IO::Async::Loop::Glib->new;
}

lazy window => method() {
	(InstanceOf['Gtk3::Window'])->(
		$self->builder->get_object('main-window')
	);
}, isa => InstanceOf['Gtk3::Window'];

lazy content_box => method() {
	(InstanceOf['Gtk3::Box'])->(
		Gtk3::Box->new( 'horizontal', 0 )
	);
}, isa => InstanceOf['Gtk3::Box'];

method setup_window() {
	$self->builder->get_object('application-vbox')
		->pack_start( $self->content_box, TRUE, TRUE, 0 );
}

method show_all() {
	$self->window->show_all;
}

method BUILD(@) {
	$self->setup_window;

	$self->window->signal_connect(
		destroy => \&on_application_quit_cb, $self );
	$self->window->set_default_size( 800, 600 );
}

# Callbacks {{{
callback on_application_quit_cb( $event, $self ) {
	Gtk3::main_quit;
}
# }}}

with qw(
	Intertangle::API::Gtk3::Component::Role::FromBuilder
	Intertangle::API::Gtk3::Component::Role::UIFileFromPackageName
	MooX::Role::Logger

	Renard::Curie::Component::MainWindow::Role::PageDrawingArea

	Renard::Curie::Component::MainWindow::Role::DragAndDrop
	Renard::Curie::Component::MainWindow::Role::LogWindow
	Renard::Curie::Component::MainWindow::Role::AccelMap
	Renard::Curie::Component::MainWindow::Role::MenuBar
	Renard::Curie::Component::MainWindow::Role::Outline
	Renard::Curie::Component::MainWindow::Role::TTSWindow
	Renard::Curie::Component::MainWindow::Role::ExceptionHandler
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::MainWindow - Main window of the application

=head1 VERSION

version 0.005

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 CONSUMES

=over 4

=item * L<Intertangle::API::Gtk3::Component::Role::FromBuilder>

=item * L<Intertangle::API::Gtk3::Component::Role::UIFileFromPackageName>

=item * L<MooX::Role::Logger>

=item * L<Renard::Curie::Component::MainWindow::Role::AccelMap>

=item * L<Renard::Curie::Component::MainWindow::Role::DragAndDrop>

=item * L<Renard::Curie::Component::MainWindow::Role::ExceptionHandler>

=item * L<Renard::Curie::Component::MainWindow::Role::LogWindow>

=item * L<Renard::Curie::Component::MainWindow::Role::MenuBar>

=item * L<Renard::Curie::Component::MainWindow::Role::Outline>

=item * L<Renard::Curie::Component::MainWindow::Role::PageDrawingArea>

=item * L<Renard::Curie::Component::MainWindow::Role::TTSWindow>

=back

=head1 ATTRIBUTES

=head2 loop

Glib event loop.

=head2 window

A L<Gtk3::Window> that contains the main window for the application.

=head2 content_box

A horizontal L<Gtk3::Box> which is used to split the main application area into
two different regions.

The left region contains L</outline> and the right region contains L</page_document_component>.

=head1 METHODS

=head2 setup_window

  method setup_window()

Sets up components that make up the window shell for the application
including:

=over 4

=item *

L</menu_bar>

=item *

L</content_box>

=item *

L</log_window>

=back

=head2 show_all

  method show_all()

Shows the C<window> widget of this component and its subwidgets.

=head2 BUILD

  method BUILD

Initialises the application and sets up signals.

=head1 CALLBACKS

=head2 on_application_quit_cb

  callback on_application_quit_cb( $event, $self )

Callback that stops the L<Gtk3> main loop.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
