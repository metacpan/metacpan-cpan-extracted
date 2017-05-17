#!/usr/bin/env perl

use Test::Most tests => 1;

use lib 't/lib';
use CurieTestHelper;

use Renard::Curie::Setup;
use Renard::Curie::Model::Document::CairoImageSurface;

subtest 'Cairo document model' => sub {
	my $cairo_doc = CurieTestHelper->create_cairo_document;
	Role::Tiny->apply_roles_to_object( $cairo_doc,
		qw(Renard::Curie::Model::Document::Role::Cacheable) );
	my $first_page = $cairo_doc->get_rendered_page( page_number => 1 );

	cmp_deeply(
		[ $cairo_doc->render_cache->get_keys ],
		bag('{"page_number":1}'),
		'cache contains the first page' );
};


done_testing;
