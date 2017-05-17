#!/usr/bin/env perl

use Test::Most tests => 4;
use Test::Trap;

use lib 't/lib';
use CurieTestHelper;

use Renard::Curie::Setup;
use Renard::Curie::App;
use File::Temp;
use URI::file;
use Test::MockObject;
use version 0.77 ();

subtest "Process arguments" => sub {
	subtest "Process arguments for PDF file" => sub {
		my $pdf_ref_path = try {
			CurieTestHelper->test_data_directory->child(qw(PDF Adobe pdf_reference_1-7.pdf));
		} catch {
			plan skip_all => "$_";
		};
		my $app = Renard::Curie::App->new;
		local @ARGV = ($pdf_ref_path);
		$app->process_arguments;
		like $app->window->get_title, qr/\Q$pdf_ref_path\E/, "Window title contains path to file";
		undef $app;
	};

	subtest "Process no arguments" => sub {
		my $app = Renard::Curie::App->new;
		local @ARGV = ();
		lives_ok {
			$app->process_arguments;
		} 'Processes no arguments fine';
		undef $app;
	};

	subtest "Process arguments for non-existent file" => sub {
		my $non_existent_filename = File::Temp::tmpnam();
		local @ARGV = ($non_existent_filename);
		my $app = Renard::Curie::App->new;
		throws_ok {
			$app->process_arguments;
		} 'Renard::Curie::Error::IO::FileNotFound', "Throws exception when file not found";
		undef $app;
	};

	subtest "Process --help flag" => sub {
		my $app = Renard::Curie::App->new;
		local @ARGV = qw(--help);
		trap { $app->process_arguments; };
		like( $trap->stdout, qr/--help/, 'Shows usage text' );
		is( $trap->exit, 0, 'Exits successfully after call' );
		undef $app;
	};

	subtest "Process --version flag" => sub {
		my $app = Renard::Curie::App->new;
		local @ARGV = qw(--version);
		trap { $app->process_arguments; };
		like( $trap->stdout, qr/Project Renard Curie/, 'Prints full name of application' );
		is( $trap->exit, 0, 'Exits successfully after call' );
		undef $app;
	};

	subtest "Process --short-version flag" => sub {
		my $app = Renard::Curie::App->new;
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
	my $app = Renard::Curie::App->new;

	Glib::Timeout->add(100, sub {
		cmp_ok( Gtk3::main_level, '>', 0, 'Main loop is running');
		$app->window->destroy;
	});

	$app->main;

	is( Gtk3::main_level, 0, 'Main loop is no longer running');

	undef $app;
};

subtest "Open document twice" => sub {
	my $app = Renard::Curie::App->new;
	my $cairo_doc_a = CurieTestHelper->create_cairo_document;
	my $cairo_doc_b = CurieTestHelper->create_cairo_document;

	$app->open_document($cairo_doc_a);
	cmp_deeply $app->page_document_component->document, $cairo_doc_a, 'First document loaded';

	$app->open_document($cairo_doc_b);
	cmp_deeply $app->page_document_component->document, $cairo_doc_b, 'Second document loaded';

	undef $app;
};

subtest "Drag and drop of file" => sub {
	my $pdf_ref_path = try {
		CurieTestHelper->test_data_directory->child(qw(PDF Adobe pdf_reference_1-7.pdf));
	} catch {
		plan skip_all => "$_";
	};

	my $pdf_ref_uri = URI::file->new($pdf_ref_path);

	my $app = Renard::Curie::App->new;
	my $data = Test::MockObject->new( ); # mocking Gtk3::SelectionData
	$data->mock( get_uris => sub { [ "$pdf_ref_uri" ] } );

	my $info = Renard::Curie::App::DND_TARGET_URI_LIST;

	my @signal_args = (
		undef, # $context
		0,     # $x
		0,     # $y
		$data, # $data
		$info, # $info
		0, # $time
		$app, # $app
	);

	Renard::Curie::App::on_drag_data_received_cb( $app->content_box, @signal_args);

	is(  $app->page_document_component->document->filename, "$pdf_ref_path", "Drag and drop opened correct file" );

	undef $app;
};
