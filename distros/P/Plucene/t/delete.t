#!/usr/bin/perl

=head1 NAME

delete.t - tests documents are deleted successfully

=cut

use strict;
use warnings;

use Plucene::TestCase;

use Plucene::Index::Term;
use File::Slurp;

use Test::More tests => 3;

#------------------------------------------------------------------------------
# Create an index
#------------------------------------------------------------------------------

# We need to create multiple segments, so make it big

my $term = "aaa";
new_index {
	add_document(contents => $term++) for (1 .. 50);
};

my $hits = search("contents:aaa");
is(@{ $hits->{hit_docs} }, 1, "Found one");
my $to_delete = Plucene::Index::Term->new({
		field => "contents",
		text  => "aaa"
	});
with_reader {
	$READER->delete_term($to_delete);
};

with_reader {
	ok($READER->is_deleted(0), "aaa marked as deleted");
};

$hits = search("contents:aaa");
is(@{ $hits->{hit_docs} }, 0, "Found nil");
