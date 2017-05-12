#!/usr/bin/env perl

use Test::Most tests => 2;

use lib 't/lib';
use CurieTestHelper;

use Renard::Curie::Setup;
use Renard::Curie::Helper;
use Renard::Curie::App;
use Renard::Curie::Component::FileChooser;
use Test::MockModule;
use Function::Parameters;

subtest 'Check that the open file dialog with filters is created' => fun {
	my $app = Renard::Curie::App->new;
	my $file_chooser = Renard::Curie::Component::FileChooser->new( app => $app );

	my $dialog = $file_chooser->get_open_file_dialog_with_filters;

	is $dialog->get_title, 'Open File', 'Dialog has the right title';

	my $filters = $dialog->list_filters;
	my @filters_names = map { $_->get_name } @$filters;

	cmp_deeply(\@filters_names, bag('All files', 'PDF files'),
		'Has expected filters' );
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
			on_menu_file_open_activate_cb => undef );

		ok( $got_file, "Callback retrieved the filename");
		ok( $destroyed, "Callback destroyed the dialog");
	};

	subtest "Cancel dialog" => fun {
		($got_file, $destroyed) = (0, 0);
		$fc->mock( run => 'cancel' );

		my $app = Renard::Curie::App->new;
		Renard::Curie::Helper->callback( $app->menu_bar,
			on_menu_file_open_activate_cb => undef );
		ok(!$got_file, "Callback did not retrieve the filename");
		ok( $destroyed, "Callback destroyed the dialog");
	};
};
