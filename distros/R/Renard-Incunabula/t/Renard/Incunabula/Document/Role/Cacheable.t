#!/usr/bin/env perl

use Test::Most tests => 1;

use lib 't/lib';
use Renard::Incunabula::Devel::TestHelper;

use Renard::Incunabula::Common::Setup;
use Renard::Incunabula::Format::Cairo::ImageSurface::Document;

subtest 'Cairo document model' => sub {
	my $cairo_doc = Renard::Incunabula::Devel::TestHelper->create_cairo_document;
	Role::Tiny->apply_roles_to_object( $cairo_doc,
		qw(Renard::Incunabula::Document::Role::Cacheable) );
	my $first_page = $cairo_doc->get_rendered_page( page_number => 1 );

	cmp_deeply(
		[ $cairo_doc->render_cache->get_keys ],
		bag('{"page_number":1}'),
		'cache contains the first page' );
};


done_testing;
