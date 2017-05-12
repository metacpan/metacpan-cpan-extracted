#!/usr/bin/perl -w

=head1 NAME 

t/datesearch.t - test Plucene::Simple

=head1 DESCRIPTION

Tests the search_during ability of Plucene::Simple.

=cut

use strict;
use warnings;

use Plucene::Simple;

use File::Path;
use Test::More tests => 8;
use Time::Piece;

use constant DIRECTORY => "/tmp/testindex/$$";

END { rmtree DIRECTORY }

#------------------------------------------------------------------------------
# Helper stuff
#------------------------------------------------------------------------------

sub data {
	return [
		wsc => { name => "Writing Solid Code", date => Time::Piece->new->ymd },
		rap => { name => "Rapid Development" },
		gui => { name => "GUI Bloopers",       date => "1972-06-15" },
		ora => { name => "Using Oracle 8i" },
		app => { name => "Advanced Perl Programming", date => "1996-07-05" },
		xpe => { name => "Extreme Programming Explained" },
		boo => { name => "Boo-Hoo",                   date => "1996-03-19" },
		dbs => { name => "Designing From Both Sides of the Screen" },
		dbi => { name => "Programming the Perl DBI", date => "1998-03-17" },
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

{    # search the index between 1972 - 1998
	my $plucy = Plucene::Simple->open(DIRECTORY);
	my @docs = $plucy->search_during("name:perl", "1972-06-01", "1998-12-25");
	is @docs, 2, "2 results for Perl between 1972 and 1998";
	is_deeply \@docs, [ "dbi", "app" ], "The correct ones";
}

{    # search the index between 1997 - 1998
	my $plucy = Plucene::Simple->open(DIRECTORY);
	my @docs = $plucy->search_during("name:perl", "1997-01-01", "1998-12-25");
	is @docs, 1, "1 result for Perl between 1997 and 1998";
	is_deeply \@docs, ["dbi"], "The correct one";
}

{    # search the index between 1997 - 1998 (dates passed in different order)
	my $plucy = Plucene::Simple->open(DIRECTORY);
	my @docs = $plucy->search_during("name:perl", "1998-12-25", "1997-01-01");
	is @docs, 1, "1 result for Perl between 1997 and 1998";
	is_deeply \@docs, ["dbi"], "The correct one";
}

{    # search the index between post 1998
	my $plucy = Plucene::Simple->open(DIRECTORY);
	my @docs  =
		$plucy->search_during("name:perl", "1998-12-25", Time::Piece->new->ymd);
	is @docs, 0, "No results for Perl between 1998 and now";
}

