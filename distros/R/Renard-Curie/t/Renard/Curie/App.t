#!/usr/bin/env perl

use Test::Most tests => 3;

use lib 't/lib';
use CurieTestHelper;

use Renard::Curie::Setup;
use Renard::Curie::App;
use File::Temp;
use Function::Parameters;

subtest "Process arguments" => fun {
	subtest "Process arguments for PDF file" => fun {
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

	subtest "Process no arguments" => fun {
		my $app = Renard::Curie::App->new;
		local @ARGV = ();
		lives_ok {
			$app->process_arguments;
		} 'Processes no arguments fine';
		undef $app;
	};

	subtest "Process arguments for non-existent file" => fun {
		my $non_existent_filename = File::Temp::tmpnam();
		local @ARGV = ($non_existent_filename);
		my $app = Renard::Curie::App->new;
		throws_ok {
			$app->process_arguments;
		} 'Renard::Curie::Error::IO::FileNotFound', "Throws exception when file not found";
		undef $app;
	};
};

subtest "Run app and destroy" => fun {
	plan tests => 2;
	my $app = Renard::Curie::App->new;

	Glib::Timeout->add(100, fun {
		cmp_ok( Gtk3::main_level, '>', 0, 'Main loop is running');
		$app->window->destroy;
	});

	$app->main;

	is( Gtk3::main_level, 0, 'Main loop is no longer running');

	undef $app;
};

subtest "Open document twice" => fun {
	my $app = Renard::Curie::App->new;
	my $cairo_doc_a = CurieTestHelper->create_cairo_document;
	my $cairo_doc_b = CurieTestHelper->create_cairo_document;

	$app->open_document($cairo_doc_a);
	cmp_deeply $app->page_document_component->document, $cairo_doc_a, 'First document loaded';

	$app->open_document($cairo_doc_b);
	cmp_deeply $app->page_document_component->document, $cairo_doc_b, 'Second document loaded';

	undef $app;
};
