#!/usr/bin/env perl

use Test::Most tests => 7;

use lib 't/lib';
use CurieTestHelper;

use Renard::Curie::Setup;
use Renard::Curie::Helper;
use Gtk3;
use URI::file;
use List::AllUtils qw(first);
use Test::MockModule;
use Test::MockObject;

subtest 'Check that the menu item File -> Open exists' => sub {
	require Renard::Curie::App;
	my $app = Renard::Curie::App->new;

	my $menu_bar = $app->menu_bar->get_child;
	my @toplevel = $menu_bar->get_children;
	my $file_menu = first {
		$_->get_property('label') eq '_File'
	} @toplevel;
	my $file_submenu = $file_menu->get_submenu;
	my @file_submenu_labels = map {
		$_->get_property('label')
	} $file_submenu->get_children;

	cmp_deeply(\@file_submenu_labels, supersetof('gtk-open'),
		'File -> Open menu item exists' );
};

subtest "Menu: File -> Open" => sub {
	my $pdf_ref_path = try {
		CurieTestHelper->test_data_directory->child(qw(PDF Adobe pdf_reference_1-7.pdf));
	} catch {
		plan skip_all => "$_";
	};

	my $fc = Test::MockModule->new('Gtk3::FileChooserDialog', no_auto => 1);
	my ($got_file, $destroyed) = (0, 0);
	$fc->mock( get_filename => sub { $got_file = 1; "$pdf_ref_path" } );
	$fc->mock( destroy => sub { $destroyed = 1 } );

	subtest "Accept dialog" => sub {
		($got_file, $destroyed) = (0, 0);
		$fc->mock( run => 'accept' );

		my $app = Renard::Curie::App->new;
		Renard::Curie::Helper->callback( $app->menu_bar,
			'on_menu_file_open_activate_cb', undef );

		ok( $got_file, "Callback retrieved the filename");
		ok( $destroyed, "Callback destroyed the dialog");
	};

	subtest "Cancel dialog" => sub {
		($got_file, $destroyed) = (0, 0);
		$fc->mock( run => 'cancel' );

		my $app = Renard::Curie::App->new;
		Renard::Curie::Helper->callback( $app->menu_bar,
			'on_menu_file_open_activate_cb', undef );
		ok(!$got_file, "Callback did not retrieve the filename");
		ok( $destroyed, "Callback destroyed the dialog");
	};
};

subtest "Menu: File -> Quit" => sub {
	plan tests => 2;
	my $app = Renard::Curie::App->new;

	Glib::Timeout->add(100, sub {
		cmp_ok( Gtk3::main_level, '>', 0, 'Main loop is running');
		$app->menu_bar->builder
			->get_object('menu-item-file-quit')
			->signal_emit('activate');
	});

	$app->run;

	is( Gtk3::main_level, 0, 'Main loop is no longer running');
};

subtest "Menu: File -> Recent files" => sub {
	my $pdf_ref_path = try {
		CurieTestHelper->test_data_directory->child(qw(PDF Adobe pdf_reference_1-7.pdf));
	} catch {
		plan skip_all => "$_";
	};

	$pdf_ref_path = $pdf_ref_path->absolute;
	my $pdf_ref_uri = URI::file->new_abs( $pdf_ref_path );

	my $pdf_ref_menu_item = Test::MockObject->new;
	$pdf_ref_menu_item->mock( get_uri => sub { $pdf_ref_uri } );

	my $rc_mock = Test::MockModule->new('Gtk3::RecentChooser', no_auto => 1);
	$rc_mock->mock( get_current_item => $pdf_ref_menu_item );

	my $app = Renard::Curie::App->new;
	my $menu_bar = $app->menu_bar;
	my $rc = $menu_bar->recent_chooser;

	$rc->signal_emit('item-activated');

	is path($app->page_document_component->document->filename), $pdf_ref_path, 'File opened from Recent files';
};

subtest "Menu: View -> Zoom" => sub {
	my $pdf_ref_path = try {
		CurieTestHelper->test_data_directory->child(qw(PDF Adobe pdf_reference_1-7.pdf));
	} catch {
		plan skip_all => "$_";
	};

	plan tests => 4;

	my $app = Renard::Curie::App->new;
	$app->open_pdf_document( $pdf_ref_path );

	my $zoom_menu = $app->menu_bar->builder
		->get_object('menu-view-zoom');

	my @menu_item_zoom_levels = $zoom_menu->get_children;
	my %zoom_label_to_item = map {
		( $_->get_property('label') => $_ )
	} @menu_item_zoom_levels;

	my $get_zoom_level = sub {
		$app->page_document_component->zoom_level;
	};

	subtest 'Initial zoom' => sub {
		is $get_zoom_level->(), 1.0, 'Zoom starts at 100%';
	};

	subtest 'Select 50% zoom menu item' => sub {
		$zoom_label_to_item{'50%'}->signal_emit('activate');
		is $get_zoom_level->(), 0.5, 'Zoom is now 50%';
	};

	subtest 'Select 200% zoom menu item' => sub {
		$zoom_label_to_item{'200%'}->signal_emit('activate');
		is $get_zoom_level->(), 2.0, 'Zoom is now 200%';
	};

	subtest 'Select 100% zoom menu item' => sub {
		$zoom_label_to_item{'100%'}->signal_emit('activate');
		is $get_zoom_level->(), 1.0, 'Zoom is now back at 100%';
	};
};

subtest "Menu: View -> Sidebar" => sub {
	plan tests => 1;
	my $app = Renard::Curie::App->new;

	my $initial_outline_reveal = $app->outline->get_reveal_child;

	$app->menu_bar->builder
		->get_object('menu-item-view-sidebar')
		->signal_emit('activate');

	my $post_outline_reveal = $app->outline->get_reveal_child;
	isnt( $post_outline_reveal, $initial_outline_reveal,
		'outline reveal state has been toggled' );
};

subtest "Menu: Help -> Message log" => sub {
	plan tests => 2;
	my $app = Renard::Curie::App->new;

	my $log_window = $app->log_window->builder->get_object('log-window');

	ok( ! $log_window->get_visible, 'message log not visible at start' );

	$app->menu_bar->builder
		->get_object('menu-item-help-logwin')
		->signal_emit('activate');

	ok( $log_window->get_visible, 'message log now visible' );
};
