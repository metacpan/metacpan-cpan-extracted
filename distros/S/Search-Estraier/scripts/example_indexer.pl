#!/usr/bin/perl -w

use strict;
use Search::Estraier;

=head1 NAME

example_indexer.pl - example indexer for Search::Estraier

=cut

# create and configure node
my $node = new Search::Estraier::Node(
	url => 'http://localhost:1978/node/test',
	user => 'admin',
	passwd => 'admin'
);

# create document
my $doc = new Search::Estraier::Document;

# add attributes
$doc->add_attr('@uri', "http://estraier.gov/example.txt");
$doc->add_attr('@title', "Over the Rainbow");

# add body text to document
$doc->add_text("Somewhere over the rainbow.  Way up high.");
$doc->add_text("There's a land that I heard of once in a lullaby.");

die "error: ", $node->status,"\n" unless (eval { $node->put_doc($doc) });

