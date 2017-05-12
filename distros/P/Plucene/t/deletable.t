#!/usr/bin/perl

=head1 NAME

deletable.t - tests the contents of the deletable file

=cut

use strict;
use warnings;

use Plucene::TestCase;

use File::Slurp;

use Test::More tests => 1;

#------------------------------------------------------------------------------
# Create an index
#------------------------------------------------------------------------------

new_index {
	add_document(contents => $_) for qw/
		wsc
		rap
		gui
		ora
		app
		xpe
		boo
		dbs
		dbi
		/;
};

#------------------------------------------------------------------------------
# Tests
#------------------------------------------------------------------------------

{    # make sure there is a deletable file
	my $del = read_file($DIR . "/deletable");
	unlike $del => qr/Plucene::Index::Writer/,
		"deletable file not having rubbish written to it";
}
