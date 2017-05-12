#!/usr/bin/env perl

use Test::Most tests => 6;

use lib 't/lib';
use CurieTestHelper;

use Renard::Curie::Setup;
use Renard::Curie::Helper;
use Gtk3;
use URI::file;
use List::AllUtils qw(first);
use Test::MockModule;
use Test::MockObject;
use Function::Parameters;

subtest 'Check that the menu item File -> Open exists' => fun {
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

subtest "Menu: File -> Open" => fun {
	my $pdf_ref_path = try {
		CurieTestHelper->test_data_directory->child(qw(PDF Adobe pdf_reference_1-7.pdf));
	} catch {
		plan skip_all => "$_";
	};

	my $fc = Test::MockModule->new('Gtk3::FileChooserDialog', no_auto => 1);
	my ($got_file, $destroyed) = (0, 0);
	$fc->mock( get_filename => fun { $got_file = 1; "$pdf_ref_path" } );
	$fc->mock( destroy => fun { $destroyed = 1 } );

	subtest "Accept dialog" => fun {
		($got_file, $destroyed) = (0, 0);
		$fc->mock( run => 'accept' );

		my $app = Renard::Curie::App->new;
		Renard::Curie::Helper->callback( $app->menu_bar,
			'on_menu_file_open_activate_cb', undef );

		ok( $got_file, "Callback retrieved the filename");
		ok( $destroyed, "Callback destroyed the dialog");
	};

	subtest "Cancel dialog" => fun {
		($got_file, $destroyed) = (0, 0);
		$fc->mock( run => 'cancel' );

		my $app = Renard::Curie::App->new;
		Renard::Curie::Helper->callback( $app->menu_bar,
			'on_menu_file_open_activate_cb', undef );
		ok(!$got_file, "Callback did not retrieve the filename");
		ok( $destroyed, "Callback destroyed the dialog");
	};
};

subtest "Menu: File -> Quit" => fun {
	plan tests => 2;
	my $app = Renard::Curie::App->new;

	Glib::Timeout->add(100, fun {
		cmp_ok( Gtk3::main_level, '>', 0, 'Main loop is running');
		$app->menu_bar->builder
			->get_object('menu-item-file-quit')
			->signal_emit('activate');
	});

	$app->run;

	is( Gtk3::main_level, 0, 'Main loop is no longer running');
};

subtest "Menu: File -> Recent files" => fun {
	my $pdf_ref_path = try {
		CurieTestHelper->test_data_directory->child(qw(PDF Adobe pdf_reference_1-7.pdf));
	} catch {
		plan skip_all => "$_";
	};

	$pdf_ref_path = $pdf_ref_path->absolute;
	my $pdf_ref_uri = URI::file->new_abs( $pdf_ref_path );

	my $pdf_ref_menu_item = Test::MockObject->new;
	$pdf_ref_menu_item->mock( get_uri => fun { $pdf_ref_uri } );

	my $rc_mock = Test::MockModule->new('Gtk3::RecentChooser', no_auto => 1);
	$rc_mock->mock( get_current_item => $pdf_ref_menu_item );

	my $app = Renard::Curie::App->new;
	my $menu_bar = $app->menu_bar;
	my $rc = $menu_bar->recent_chooser;

	$rc->signal_emit('item-activated');

	is path($app->page_document_component->document->filename), $pdf_ref_path, 'File opened from Recent files';
};

subtest "Menu: View -> Sidebar" => fun {
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

subtest "Menu: Help -> Message log" => fun {
	plan tests => 2;
	my $app = Renard::Curie::App->new;

	my $log_window = $app->log_window->builder->get_object('log-window');

	ok( ! $log_window->get_visible, 'message log not visible at start' );

	$app->menu_bar->builder
		->get_object('menu-item-help-logwin')
		->signal_emit('activate');

	ok( $log_window->get_visible, 'message log now visible' );
};
