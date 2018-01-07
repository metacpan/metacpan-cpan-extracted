#!/usr/bin/env perl

use Test::Most tests => 5;
use Test::Trap;
use Test::Exception 0.43;

use lib 't/lib';
use CurieTestHelper;
use Renard::Incunabula::Devel::TestHelper;
use Renard::Incunabula::Format::Cairo::Devel::TestHelper;

use Renard::Incunabula::Common::Setup;
use Renard::Curie::Container::App;
use Renard::Curie::App;
use File::Temp;
use URI::file;
use Test::MockObject;
use Test::MockModule;
use version 0.77 ();

subtest "Process arguments" => sub {
	subtest "Process arguments for PDF file" => sub {
		my $pdf_ref_path = try {
			Renard::Incunabula::Devel::TestHelper->test_data_directory->child(qw(PDF Adobe pdf_reference_1-7.pdf));
		} catch {
			plan skip_all => "$_";
		};
		my $c = CurieTestHelper->get_app_container;
		my $app = $c->app;
		local @ARGV = ($pdf_ref_path);
		$app->process_arguments;
		like $c->main_window->window->get_title, qr/\Q$pdf_ref_path\E/, "Window title contains path to file";
		undef $app;
	};

	subtest "Process no arguments" => sub {
		my $app = CurieTestHelper->get_app_container->app;
		local @ARGV = ();
		lives_ok {
			$app->process_arguments;
		} 'Processes no arguments fine';
		undef $app;
	};

	subtest "Process arguments for non-existent file" => sub {
		my $non_existent_filename = File::Temp::tmpnam();
		local @ARGV = ($non_existent_filename);
		my $app = CurieTestHelper->get_app_container->app;
		throws_ok {
			$app->process_arguments;
		} 'Renard::Incunabula::Common::Error::IO::FileNotFound', "Throws exception when file not found";
		undef $app;
	};

	subtest "Process --help flag" => sub {
		my $app = CurieTestHelper->get_app_container->app;
		local @ARGV = qw(--help);
		trap { $app->process_arguments; };
		like( $trap->stdout, qr/--help/, 'Shows usage text' );
		is( $trap->exit, 0, 'Exits successfully after call' );
		undef $app;
	};

	subtest "Process --version flag" => sub {
		my $app = CurieTestHelper->get_app_container->app;
		local @ARGV = qw(--version);
		trap { $app->process_arguments; };
		like( $trap->stdout, qr/Project Renard Curie/, 'Prints full name of application' );
		is( $trap->exit, 0, 'Exits successfully after call' );
		undef $app;
	};

	subtest "Process --short-version flag" => sub {
		my $app = CurieTestHelper->get_app_container->app;
		local @ARGV = qw(--short-version);
		trap { $app->process_arguments; };
		chomp( my $version_or_dev = $trap->stdout );
		note "Got version: $version_or_dev";
		if( $version_or_dev =~ qr/^dev$/ ) {
			pass( 'Prints out dev as version' );
		} else {
			lives_ok {
				version->parse($version_or_dev);
			} "version parses";
		}
		is( $trap->exit, 0, 'Exits successfully after call' );
		undef $app;
	};
};

subtest "Run app and destroy" => sub {
	plan tests => 2;
	my $c = CurieTestHelper->get_app_container;
	my $app = $c->app;

	Glib::Timeout->add(100, sub {
		cmp_ok( Gtk3::main_level, '>', 0, 'Main loop is running');
		$c->main_window->window->destroy;
	});

	$app->main;

	is( Gtk3::main_level, 0, 'Main loop is no longer running');

	undef $app;
};

subtest "Open document twice" => sub {
	my $c = CurieTestHelper->get_app_container;
	my $app = $c->app;
	my $cairo_doc_a = Renard::Incunabula::Format::Cairo::Devel::TestHelper->create_cairo_document;
	my $cairo_doc_b = Renard::Incunabula::Format::Cairo::Devel::TestHelper->create_cairo_document;

	$c->view_manager->current_document($cairo_doc_a);
	cmp_deeply $c->_test_current_view->document, $cairo_doc_a, 'First document loaded';

	$c->view_manager->current_document($cairo_doc_b);
	cmp_deeply $c->_test_current_view->document, $cairo_doc_b, 'Second document loaded';

	undef $app;
};

subtest "Drag and drop of file" => sub {
	my $pdf_ref_path = try {
		Renard::Incunabula::Devel::TestHelper->test_data_directory->child(qw(PDF Adobe pdf_reference_1-7.pdf));
	} catch {
		plan skip_all => "$_";
	};

	my $pdf_ref_uri = URI::file->new($pdf_ref_path);
	my $c = CurieTestHelper->get_app_container;

	my @tests = (
		{
			name => 'text/uri-list',
			info => $c->main_window->DND_TARGET_URI_LIST,
			mock => sub {
				my $data = Test::MockObject->new( ); # mocking Gtk3::SelectionData
				$data->mock( get_uris => sub { [ "$pdf_ref_uri" ] } );
				$data;
			},
		},
		{
			name => 'text/plain',
			info => $c->main_window->DND_TARGET_TEXT,
			mock => sub {
				my $data = Test::MockObject->new( ); # mocking Gtk3::SelectionData
				$data->mock( get_text => sub { "$pdf_ref_uri" } );
				$data;
			},
		},
	);

	plan tests => scalar @tests;

	for my $test (@tests) {
		subtest "Name: $test->{name}" => sub {
			my $app = $c->app;

			my $data = $test->{mock}->();
			my $info = $test->{info};

			my @signal_args = (
				undef, # $context
				0,     # $x
				0,     # $y
				$data, # $data
				$info, # $info
				0,     # $time
				$c->main_window, # $main_window
			);

			Renard::Curie::Component::MainWindow::on_drag_data_received_cb( $c->main_window->content_box, @signal_args );

			is(  $c->_test_current_view->document->filename, "$pdf_ref_path", "Drag and drop opened correct file" );

			undef $app;
		};
	}
};

subtest "Opening document adds to recent manager" => sub {
	my $pdf_ref_path = try {
		Renard::Incunabula::Devel::TestHelper->test_data_directory->child(qw(PDF Adobe pdf_reference_1-7.pdf));
	} catch {
		plan skip_all => "$_";
	};

	my $pdf_ref_uri = URI::file->new($pdf_ref_path);

	my $added_item;
	my $rm = Test::MockModule->new('Gtk3::RecentManager', no_auto => 1);
	$rm->mock( add_item => method($item) { $added_item = $item; 1; } );

	my $c = CurieTestHelper->get_app_container;
	my $app = $c->app;
	$c->view_manager->open_pdf_document( $pdf_ref_path );

	is( $added_item, $pdf_ref_uri, "Got the expected item URI" );
};
