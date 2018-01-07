#!/usr/bin/env perl

use Test::Most;

use lib 't/lib';
use Renard::Incunabula::Common::Setup;
use Renard::Curie::App;
use CurieTestHelper;
use Renard::Incunabula::Format::Cairo::Devel::TestHelper;
use Renard::Incunabula::Common::Types qw(Int InstanceOf);

my $cairo_doc = Renard::Incunabula::Format::Cairo::Devel::TestHelper->create_cairo_document;

fun Key_Event( (InstanceOf['Renard::Curie::Component::PageDrawingArea']) $pd, (Int) $key) {
	my $event = Gtk3::Gdk::Event->new('key-press');
	$event->keyval($key);
	$pd->signal_emit( key_press_event => $event );
}

subtest 'Check that Page Down moves forward a page and Page Up moves back a page' => sub {
	my ( $app, $page_comp ) = CurieTestHelper->create_app_with_document($cairo_doc);

	is($page_comp->view->page_number, 1, 'Start on page 1' );

	Key_Event($page_comp, Gtk3::Gdk::KEY_Page_Down);
	is($page_comp->view->page_number, 2, 'On page 2 after hitting Page Down' );

	Key_Event($page_comp, Gtk3::Gdk::KEY_Page_Up);
	is($page_comp->view->page_number, 1, 'On page 1 after hitting Page Up' );
};

subtest 'Check that up arrow scrolls up and down arrow scrolls down' => CurieTestHelper->run_app_with_document($cairo_doc, sub {
	plan tests => 2;
	my ( $app, $page_comp ) = @_;

	Glib::Timeout->add(200, sub {
		my $vadj = $page_comp->scrolled_window->get_vadjustment;
		my $current_value = $vadj->get_value;
		Key_Event($page_comp, Gtk3::Gdk::KEY_Down);
		my $next_value = $vadj->get_value;
		cmp_ok( $current_value, '<', $next_value, 'Page has scrolled down');

		$current_value = $vadj->get_value;
		Key_Event($page_comp, Gtk3::Gdk::KEY_Up);
		$next_value = $vadj->get_value;
		cmp_ok( $current_value, '>', $next_value, 'Page has scrolled up');

		$app->main_window->window->destroy;
	});
});

subtest 'Check that right arrow scrolls right and left arrow scrolls left' => CurieTestHelper->run_app_with_document($cairo_doc, sub {
	plan tests => 2;
	my ( $app, $page_comp ) = @_;

	Glib::Timeout->add(200, sub {
		my $hadj = $page_comp->scrolled_window->get_hadjustment;
		my $current_value = $hadj->get_value;
		Key_Event($page_comp, Gtk3::Gdk::KEY_Right);
		my $next_value = $hadj->get_value;
		cmp_ok( $current_value, '<', $next_value, 'Page has scrolled right');

		$current_value = $hadj->get_value;
		Key_Event($page_comp, Gtk3::Gdk::KEY_Left);
		$next_value = $hadj->get_value;
		cmp_ok( $current_value, '>', $next_value, 'Page has scrolled left');

		$app->main_window->window->destroy;
	});
});

done_testing;
