#!/usr/bin/perl -w

=head1 NAME

regress-01.t - Add a document to an index

=cut

use strict;
use warnings;

use Plucene::TestCase;

use File::Slurp qw(read_file);
use File::Temp qw(tempdir);

use Test::More tests => 1;

$| = 0;

new_index {
	my $data = do { local $/; scalar <DATA> };
	add_document(content => $data);
	$WRITER->optimize;
};

ok(1);

__DATA__                                                                                                                                                                 
#
a
