#!/usr/bin/env perl

use Test::Most tests => 3;

use Renard::Incunabula::Common::Setup;
use Renard::Curie::App;
use Renard::Curie::Model::View;
use Renard::Curie::Model::View::Grid;
use Renard::Curie::Model::ViewOptions;
use Renard::Curie::Model::ViewOptions::Grid;

use lib 't/lib';
use CurieTestHelper;
use Renard::Incunabula::Format::Cairo::Devel::TestHelper;

fun create_grid_view( :$rows, :$columns ) {
	my $doc = Renard::Incunabula::Format::Cairo::Devel::TestHelper->create_cairo_document( repeat => 2, width => 200, height => 800 );
	my $grid_view = Renard::Curie::Model::View::Grid->new(
		view_options => Renard::Curie::Model::ViewOptions->new(
			grid_options => Renard::Curie::Model::ViewOptions::Grid->new(
				rows => $rows,
				columns => $columns,
			)
		),
		document => $doc,
	);
}

subtest "Create a grid view [r = 1, c = 3]: pages = 8" => sub {
	my $grid_view = create_grid_view( rows => 1, columns => 3 );
	my $schemes = $grid_view->_grid_schemes;

	is( scalar @$schemes, 3, 'correct number of schemes' );
	is( $schemes->[0]->rows, 1, 'rows is correct' );
	is( $schemes->[0]->columns, 3, 'columns is correct' );

	is_deeply( [ map { $_->pages } @$schemes ],
		[
			[ 1, 2, 3 ],
			[ 4, 5, 6 ],
			[ 7, 8,   ],
		],
		'correct page partitioning',
	);
};

subtest "Create a grid view [r = undef, c = 3]: pages = 8" => sub {
	my $grid_view = create_grid_view( rows => undef, columns => 3 );
	my $schemes = $grid_view->_grid_schemes;

	is( scalar @$schemes, 1, 'there is only one scheme for a continuous view' );
	is( $schemes->[0]->rows, 3, 'rows is correct (calculated)' );
	is( $schemes->[0]->columns, 3, 'columns is correct' );

	is_deeply( $schemes->[0]->pages, [ 1 .. 8 ], 'first scheme has all pages' );
};

subtest "Create a grid view [r = 1, c = undef]: pages = 8" => sub {
	my $grid_view = create_grid_view( rows => 1, columns => undef );
	my $schemes = $grid_view->_grid_schemes;

	is( scalar @$schemes, 1, 'there is only one scheme for a continuous view' );
	is( $schemes->[0]->rows, 1, 'rows is correct' );
	is( $schemes->[0]->columns, 8, 'columns is correct (calculated)' );

	is_deeply( $schemes->[0]->pages, [ 1 .. 8 ], 'first scheme has all pages' );
};

done_testing;
