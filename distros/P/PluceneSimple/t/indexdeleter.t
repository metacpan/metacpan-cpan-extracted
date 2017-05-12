#!/usr/bin/perl -w

=head1 NAME 

t/indexdeleter.t - test Plucene::Simple

=head1 DESCRIPTION

Tests searching after everything has been removed from an index.

=cut

use strict;
use warnings;

use Plucene::Simple;

use File::Path;
use Test::More tests => 4;

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

my $plucy;

{    # Add some stuff into the index
	my @data = @{ data() };
	isa_ok $plucy = Plucene::Simple->open(DIRECTORY) => 'Plucene::Simple';
	$plucy->add(@data);
}

{    # search the index
	my @docs = $plucy->search("name:perl");
	is @docs, 2, "2 results for Perl";
	is_deeply \@docs, [ "app", "dbi" ], "The correct ones";
}

{    # delete everything from the index
	my @data = @{ data() };
	while (my ($id, $terms) = splice @data, 0, 2) {
		$plucy->delete_document($id);
	}
}

{    # search again
	my @docs = $plucy->search("name:oracle");
	is @docs, 0, "No results for oracle (after deletion)";
}
