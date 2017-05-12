#!/usr/bin/perl

=head1 NAME

t/multiple_fields.t - Using Plucene::Simple::add with multiple fields

=head1 DESCRIPTION

This tests adding multiple fields to an index.

=cut

use strict;
use warnings;

use Plucene::Simple;
use File::Path;

use Test::More tests => 4;

use constant DIR => "/tmp/testindex/$$";

END { rmtree DIR }

my $plucy = Plucene::Simple->open(DIR);

$plucy->add(
	1,
	{
		title  => "Moby-Dick",
		author => "Herman Melville",
		text   => "Call me Ishmael ...",
	},
	2,
	{
		title  => "Boo-Hoo",
		author => "Lydia Lee",
		text   => 'foo',
	},
);
$plucy->index_document('Moby Dick Chapter 1', 'Call me Ishmael ...');
$plucy->optimize;

$plucy = Plucene::Simple->open(DIR);

{
	my @ids = $plucy->search("author:lee");
	is scalar @ids, 1, "One result for author:lee...";
	is $ids[0] => 2, "...with the correct id";
}

{
	my @ids = $plucy->search("ishmael");
	is scalar @ids => 2, "Two results for 'ishmael'...";
	is_deeply \@ids, [ "Moby Dick Chapter 1", 1 ], "...the correct ones";
}
