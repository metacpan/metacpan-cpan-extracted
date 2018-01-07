#!/usr/bin/env perl

use Test::Most tests => 5;

use lib 't/lib';
use Renard::Incunabula::Common::Setup;
use Renard::Curie::App;
use CurieTestHelper;
use Renard::Incunabula::Format::Cairo::Devel::TestHelper;
use Renard::Incunabula::Common::Types qw(InstanceOf Enum);

my $cairo_doc = Renard::Incunabula::Format::Cairo::Devel::TestHelper->create_cairo_document;

fun Scroll_Event( (InstanceOf['Renard::Curie::Component::PageDrawingArea']) $pd,
		(Enum[qw(up down smooth)]) $direction,
		$delta = 0) {
	my $event = Gtk3::Gdk::Event->new('scroll');
	$event->state( 'control-mask' );
	$event->direction( $direction );
	if ( $direction eq 'smooth' ) {
		$event->delta_y( $delta );
	}
	$pd->scrolled_window->signal_emit(
		'scroll-event' => $event );
}

subtest 'Check that ctrl+scroll-down zooms out of the page' => sub {
	my ( $app, $page_comp ) = CurieTestHelper->create_app_with_document($cairo_doc);

	ok($page_comp->view->zoom_level - 1.0 < .001, 'Start at Zoom Level 1.0' );

	Scroll_Event( $page_comp, 'down' );

	ok($page_comp->view->zoom_level - .95 < .001, 'Reduce Zoom Level to .95');

	$app->main_window->window->destroy;
};

subtest 'Check that ctrl+scroll-up zooms into the page' => sub {
	my ( $app, $page_comp ) = CurieTestHelper->create_app_with_document($cairo_doc);

	ok($page_comp->view->zoom_level - 1.0 < .001, 'Start at Zoom Level 1.0' );

	Scroll_Event( $page_comp, 'up' );

	ok($page_comp->view->zoom_level - 1.05 < .001, 'Reduce Zoom Level to .95');

	$app->main_window->window->destroy;
};

subtest 'Check that ctrl+smooth-scroll-down zooms out of the page' => sub {
	my ( $app, $page_comp ) = CurieTestHelper->create_app_with_document($cairo_doc);

	ok($page_comp->view->zoom_level - 1.0 < .001, 'Start at Zoom Level 1.0' );

	Scroll_Event( $page_comp, 'smooth', -0.05 );

	ok($page_comp->view->zoom_level - .95 < .001, 'Reduce Zoom Level to .95');

	$app->main_window->window->destroy;
};

subtest 'Check that ctrl+smooth-scroll-up zooms into the page' => sub {
	my ( $app, $page_comp ) = CurieTestHelper->create_app_with_document($cairo_doc);

	ok($page_comp->view->zoom_level - 1.0 < .001, 'Start at Zoom Level 1.0' );

	Scroll_Event( $page_comp, 'smooth', 0.05 );

	ok($page_comp->view->zoom_level - 1.05 < .001, 'Reduce Zoom Level to .95');

	$app->main_window->window->destroy;
};

subtest 'Check that zooming out does not become negative' => sub {
	my ( $app, $page_comp ) = CurieTestHelper->create_app_with_document($cairo_doc);

	ok($page_comp->compute_zoom_out(1, 2) > 0,
		'start at zoom = 100% -> zoom out by 200% is still positive' );
};

done_testing;
