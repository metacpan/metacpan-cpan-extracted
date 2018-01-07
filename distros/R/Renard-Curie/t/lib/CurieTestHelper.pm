use Renard::Incunabula::Common::Setup;
package CurieTestHelper;
use Renard::Incunabula::Common::Types qw(CodeRef InstanceOf Maybe PositiveInt Tuple);
use Renard::Incunabula::Document::Types qw(DocumentModel );


=func run_app_with_document

  CurieTestHelper->run_app_with_document( $document, $callback )

Set up a L<Renard::Curie::App> application for running tests on a given
document. The main loop of the L<Renard::Curie::App> application is run after
the callback is called, so the callback should set up events to be run once the
main loop has started.

This callback set up can be accomplished by using L<Glib::Timeout>. For
example, to run code 100 ms after the main loop has started, use:

  Glib::Timeout->add(100, sub {
    ...
  });

See the L<Glib documentation|https://developer.gnome.org/glib/stable/glib-The-Main-Event-Loop.html#g-timeout-add>
for more information.

=for :list

* C<$document>:

a document that will be opened by the L<Renard::Curie::App>

* C<$callback>:

a coderef which will be passed in the L<Renard::Curie::App> C<$app> and the
current L<Renard::Curie::Component::PageDrawingArea> C<$page_component> for
the document C<$document>.

   sub {
     my ( $app, $page_component ) = @_;
     ...
   }

=cut
classmethod run_app_with_document( (DocumentModel) $document, (CodeRef) $callback) :ReturnType(CodeRef) {
	my ($app, $page_component) = $class->create_app_with_document($document);
	return sub {
		$callback->( $app, $page_component );

		$app->run;
	}
}

=func refresh_gui

  CurieTestHelper->refresh_gui( %args )

Runs the Gtk main loop until there are no more events left.

The C<%args> hash may contain the key value pair

=over 4

=item C<delay>

takes an Int value which is passed to L<C<sleep>> in order to
sleep after the events have been processed.

=back

=cut
classmethod refresh_gui( (Maybe[PositiveInt]) :$delay = ) {
	while( Gtk3::events_pending() ) {
		# do not block if there are no events left
		Gtk3::main_iteration_do(0);
	}
	sleep $delay if defined $delay;
}

=func create_app_with_document

  CurieTestHelper->create_app_with_document($document)


Creates a C<Renard::Curie::App> with a C<Renard::Incunabula::Document> C<$document> opened.

Returns two objects in a list

  ($app, $page_component)

where

=over 4

=item C<$app>

is a C<Renard::Curie::App>

=item C<$page_component>

is a C<Renard::Curie::Component::PageDrawingArea> component which contains the
document passed in C<$document>.

=back

=cut
classmethod create_app_with_document( (DocumentModel) $document )
		:ReturnType( list => Tuple[InstanceOf['Renard::Curie::App'], InstanceOf['Renard::Curie::Component::PageDrawingArea']] ) {
	my $c = $class->get_app_container;
	my $app = $c->app;
	$c->view_manager->current_document( $document );

	my $page_component = $c->main_window->page_document_component;

	$c->main_window->window->show_all;
	$class->refresh_gui;

	($app, $page_component);
}

classmethod get_app_container() :ReturnType(InstanceOf['Renard::Curie::Container::App']) {
	require Renard::Curie::Container::App;
	Renard::Curie::Container::App->new;
}

1;
