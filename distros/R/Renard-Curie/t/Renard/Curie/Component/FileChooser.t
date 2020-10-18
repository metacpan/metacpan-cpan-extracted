#!/usr/bin/env perl

use Test::Most tests => 2;

use lib 't/lib';
use CurieTestHelper;
use Renard::Block::Format::PDF::Devel::TestHelper;

use Renard::Incunabula::Common::Setup;
use Intertangle::API::Gtk3::Helper;
use Renard::Curie::App;
use Renard::Curie::Component::FileChooser;
use Test::MockModule;

subtest 'Check that the open file dialog with filters is created' => sub {
	my $c = CurieTestHelper->get_app_container;
	my $app = $c->app;
	my $file_chooser = Renard::Curie::Component::FileChooser->new( main_window => $c->main_window );

	my $dialog = $file_chooser->get_open_file_dialog_with_filters;

	is $dialog->get_title, 'Open File', 'Dialog has the right title';

	my $filters = $dialog->list_filters;
	my @filters_names = map { $_->get_name } @$filters;

	cmp_deeply(\@filters_names, bag('All files', 'PDF files'),
		'Has expected filters' );
};

subtest "Menu: File -> Open" => sub {
	my $pdf_ref_path = try {
		Renard::Block::Format::PDF::Devel::TestHelper->pdf_reference_document_path;
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

		my $c = CurieTestHelper->get_app_container;
		my $app = $c->app;
		Intertangle::API::Gtk3::Helper->callback( $c->menu_bar,
			on_menu_file_open_activate_cb => undef );

		ok( $got_file, "Callback retrieved the filename");
		ok( $destroyed, "Callback destroyed the dialog");
	};

	subtest "Cancel dialog" => sub {
		($got_file, $destroyed) = (0, 0);
		$fc->mock( run => 'cancel' );

		my $c = CurieTestHelper->get_app_container;
		my $app = $c->app;
		Intertangle::API::Gtk3::Helper->callback( $c->menu_bar,
			on_menu_file_open_activate_cb => undef );
		ok(!$got_file, "Callback did not retrieve the filename");
		ok( $destroyed, "Callback destroyed the dialog");
	};
};
