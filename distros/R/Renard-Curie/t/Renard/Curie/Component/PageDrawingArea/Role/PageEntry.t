#!/usr/bin/env perl

use Test::Most tests => 1;
use Test::MockModule;

use lib 't/lib';
use CurieTestHelper;
use Renard::Incunabula::Format::Cairo::Devel::TestHelper;

use Renard::Incunabula::Common::Setup;
use Renard::Curie::App;

my $cairo_doc = Renard::Incunabula::Format::Cairo::Devel::TestHelper->create_cairo_document;

subtest 'Check the page entry' => sub {
	my ($app, $page_comp) = CurieTestHelper->create_app_with_document($cairo_doc);

	my $entry = $page_comp->builder->get_object('page-number-entry');

	$page_comp->view->page_number(2);

	$entry->set_text('4foo');
	my $dialog = Test::MockModule->new('Gtk3::Dialog', no_auto => 1);
	$dialog->mock( run => sub {} ); # do not allow the dialog to be run
	diag "InvalidPageNumber exception will be thrown - safe to ignore";

	$entry->signal_emit('activate');

	is $page_comp->view->page_number, 2, "Page number was not changed";

	$entry->set_text('3');
	$entry->signal_emit('activate');
	is $page_comp->view->page_number, 3, "Page number was changed";
};

done_testing;
