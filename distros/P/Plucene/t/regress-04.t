#!/usr/bin/perl -w

=head1 NAME

regress-04.t - Add a document to an index with an empty field

=cut

use strict;
use warnings;

use Plucene::TestCase;

use File::Slurp qw(read_file);
use File::Temp qw(tempdir);

use Test::More tests => 1;

$| = 0;

new_index {
	add_document(content => "hello world", dummy => "");
	$WRITER->optimize;
};

ok(1);
