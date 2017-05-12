#!/usr/bin/perl -w

use strict;
use warnings;

use Plucene::TestCase;
use Plucene::Index::Reader;

use Test::More tests => 9;

#------------------------------------------------------------------------------
# Actual indexing tests
#------------------------------------------------------------------------------

new_index {
	add_document(content => "aaa") for 1 .. 100;
	is($WRITER->doc_count, 100, "Indexed all documents");
};

re_index {
	is($WRITER->doc_count, 100, "Documents are all still there");
};

with_reader {
	$READER->delete($_) for 0 .. 39;
	isa_ok(
		$READER,
		"Plucene::Index::SegmentReader",
		"There's only one segment, so we use a simple reader"
	);
	is($READER->max_doc,  100, "There's a maximum of 100");
	is($READER->num_docs, 60,  "But there's only 60 really here");
};

#------------------------------------------------------------------------------
# more tests
#------------------------------------------------------------------------------

with_reader {
	isa_ok $READER => 'Plucene::Index::Reader';
	my $exists = Plucene::Index::Reader->index_exists($DIR);
	ok $exists, "index exists";
	my $modified = Plucene::Index::Reader->last_modified($DIR);
	ok $modified, "last modified ok";
	my $lock = Plucene::Index::Reader->is_locked($DIR);
	ok !$lock, "index isn't currently locked";
	}
