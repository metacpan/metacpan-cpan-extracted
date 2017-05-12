#!/usr/bin/perl

use strict;
use warnings;

use Plucene::Simple;

use File::Temp qw/ tempdir /;
my $dir = tempdir(CLEANUP => 1);

use Test::More tests => 2;

#------------------------------------------------------------------------------
# Helper stuff
#------------------------------------------------------------------------------

sub data {
	return ({
			title    => 'The Strayest of Toasters',
			starring => 'me',
			about    => 'My life in the suicide ranks',
		},
		{
			title    => 'The Plasticest of Forks',
			starring => 'you',
			about    => "Gravity's Angel",
		},
		{
			title    => 'Poker Nights',
			starring => 'us',
			about    => 'How to lose money the easy way',
		},
		{
			title    => 'Fun in the sun',
			starring => 'me',
			about    => 'Do we ever really see the sun here?',
		},
	);
}

sub build_index {
	my $to_delete  = shift;
	my $pos        = 0;
	my @programmes = data();
	my $index      = Plucene::Simple->open($dir);
	foreach my $ref (@programmes) {
		$index->delete_document($pos) if $to_delete;
		$index->add($pos => $ref);
		$pos++;
	}
	$index->optimize;
}

#------------------------------------------------------------------------------
# Tests
#------------------------------------------------------------------------------

build_index();
my $index = Plucene::Simple->open($dir);
my @ids   = $index->search("me");
is_deeply \@ids, [ 0, 3 ], "Correct ids returned";

build_index(1);
$index = Plucene::Simple->open($dir);
@ids   = $index->search("me");
is_deeply \@ids, [ 0, 3 ],
	"Correct ids returned (after deleting them and reindexing)";
