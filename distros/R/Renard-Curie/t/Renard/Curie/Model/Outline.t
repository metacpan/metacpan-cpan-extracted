#!/usr/bin/env perl

use Test::Most;

use lib 't/lib';
use CurieTestHelper;

use Renard::Curie::Setup;
use Renard::Curie::Model::Outline;
use Renard::Curie::Model::Document::PDF;
use Function::Parameters;

my $pdf_ref_path = try {
	CurieTestHelper->test_data_directory->child(qw(PDF Adobe pdf_reference_1-7.pdf));
} catch {
	plan skip_all => "$_";
};

plan tests => 2;

fun print_tree_store($store, $callback) {
    walk_tree_store($store, fun( $level, $data ) {
	say "\t"x$level . join ":", @$data;
    });
}

fun walk_tree_store($store, $callback) {
    my $rootiter = $store->get_iter_first();
    walk_rows($store, $rootiter, 0, $callback);
}

fun walk_rows($store, $treeiter, $level, $callback) {
	my $valid = 1;
	while($valid) {
		my @array = $store->get( $treeiter, 0 .. $store->get_n_columns - 1);
		$callback->( $level, \@array );
		if( $store->iter_has_child($treeiter) ) {
			my $childiter = $store->iter_children($treeiter);
			walk_rows($store, $childiter, $level + 1, $callback);
		}
		$valid = $store->iter_next($treeiter);
	}
}

subtest 'Outline item type-checking' => fun {
	my @valid_outlines = (
		[
			{ level => 0, text  => 'Chapter 1', page  => 20, },
			{ level => 1, text  => 'Section 1.1', page  => 25, },
			{ level => 0, text  => 'Chapter 2', page  => 30, },
		]
	);

	my @invalid_outlines = (
		# level increase greater than one level
		[
			{ level => 0, text  => 'Chapter 1', page  => 20, },
			{ level => 2, text  => 'Section 1.1', page  => 25, },
			{ level => 0, text  => 'Chapter 2', page  => 30, },
		],
		# problem with page number
		[
			{ level => 0, text  => 'Chapter 1', page  => -1, },
		]
	);
	my @invalid_message = (
		qr/malformed/,
		qr/PageNumber/,
	);

	plan tests => @valid_outlines + @invalid_outlines;

	lives_ok {
		Renard::Curie::Model::Outline->new( items => $_ );
	} 'Valid outline check' for @valid_outlines;

	for (0..@invalid_outlines-1) {
		throws_ok {
			Renard::Curie::Model::Outline->new(
				items => $invalid_outlines[$_] );
			} $invalid_message[$_], 'Invalid outline exception';
	}
};

subtest 'Check that the tree store matches the items' => fun {
	my $doc = Renard::Curie::Model::Document::PDF
		->new( filename => $pdf_ref_path );
	my $outline = $doc->outline;

	#print_tree_store($app->outline->model);
	my $tree_store_data = [];
	walk_tree_store( $outline->tree_store, fun($level, $data ) {
		push @$tree_store_data,
			{
				level => $level,
				text => $data->[0],
				page => $data->[1],
			};
	});
	is_deeply( $tree_store_data, $outline->items,
		'Outline tree store matches outline items');
};

done_testing;
