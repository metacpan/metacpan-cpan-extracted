#!/usr/bin/perl -w

use strict;
use Search::Estraier;

=head1 NAME

example_searcher.pl - example searcher for Search::Estraier

=cut

# create and configure node
my $node = new Search::Estraier::Node(
	url => 'http://localhost:1978/node/test',
	user => 'admin',
	passwd => 'admin',
	croak_on_error => 1,
);

# create condition
my $cond = new Search::Estraier::Condition;

# set search phrase
$cond->set_phrase("rainbow AND lullaby");

my $nres = $node->search($cond, 0);

if (defined($nres)) {
	print "Got ", $nres->hits, " results\n";

	# for each document in results
	for my $i ( 0 ... $nres->doc_num - 1 ) {
		# get result document
		my $rdoc = $nres->get_doc($i);
		# display attribte
		print "URI: ", $rdoc->attr('@uri'),"\n";
		print "Title: ", $rdoc->attr('@title'),"\n";
		print $rdoc->snippet,"\n";
	}
} else {
	die "error: ", $node->status,"\n";
}
