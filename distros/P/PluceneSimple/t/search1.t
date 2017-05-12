#!/usr/bin/perl -w

=head1 NAME 

t/search1.t - test Plucene::Simple

=head1 DESCRIPTION

Test indexing, searching and deleting from an index.

=cut

use strict;
use warnings;

use Plucene::Simple;

use File::Path;
use Test::More tests => 13;

use constant DIRECTORY => "/tmp/testindex/$$";

END { rmtree DIRECTORY }

#------------------------------------------------------------------------------
# Helper stuff
#------------------------------------------------------------------------------

sub data {
	return [
		wsc => { name => "Writing Solid Code" },
		rap => { name => "Rapid Development" },
		gui => { name => "GUI Bloopers" },
		ora => { name => "Using Oracle 8i" },
		app => { name => "Advanced Perl Programming" },
		xpe => { name => "Extreme Programming Explained" },
		boo => { name => "Boo-Hoo" },
		dbs => { name => "Designing From Both Sides of the Screen" },
		dbi => { name => "Programming the Perl DBI" },
	];
}

#------------------------------------------------------------------------------
# Tests
#------------------------------------------------------------------------------

{    # Add some stuff into the index
	my @data = @{ data() };
	isa_ok my $plucy = Plucene::Simple->open(DIRECTORY) => 'Plucene::Simple';
	$plucy->add(@data);
}

{    # search the index
	my $plucy = Plucene::Simple->open(DIRECTORY);
	my @docs  = $plucy->search("name:perl");
	is @docs, 2, "2 results for Perl";
	is_deeply \@docs, [ "app", "dbi" ], "The correct ones";
	@docs = $plucy->search("name:illusions");
	is @docs, 0, "No results for 'illusions'";
}

{    # index another document
	my $plucy = Plucene::Simple->open(DIRECTORY);
	$plucy->index_document('boi', 'The Book of Illusions');
	my @docs = $plucy->search("illusions");
	is @docs, 1, "One result for illusions";
	is_deeply \@docs, ["boi"], "...the correct one";
}

{    # delete a document
	my $plucy = Plucene::Simple->open(DIRECTORY);
	my @docs  = $plucy->search("name:oracle");
	is @docs, 1, "One result for oracle";
	is_deeply \@docs, ["ora"], "...the correct one";
	$plucy->delete_document('ora');
	@docs = $plucy->search("name:oracle");
	is @docs, 0, "No results for oracle (after deletion)";
}

{    # bogus searches
	my $plucy = Plucene::Simple->open(DIRECTORY);
	my @docs  = $plucy->search;
	is scalar @docs, 0, "No results for no search string";
	@docs = $plucy->search("foo:bar");
	is scalar @docs, 0, "No results for foo:bar";

}

{    # Terms not in default text field
	my $plucy = Plucene::Simple->open(DIRECTORY);
	$plucy->add(
		foo => {
			name   => "The art of Unix programming",
			author => "Eric Raymond"
		});
	my @docs = $plucy->search("raymond");
	is @docs, 1, "One result for raymond";
	is_deeply \@docs, ["foo"], "...the correct one";
}
