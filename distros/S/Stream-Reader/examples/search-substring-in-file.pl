#!/usr/bin/perl -w

use strict;
use Stream::Reader;

# This example demonstrate the searching a first of substrings in some file

# Initialization the array with substrings
my @substrings = (
  'word1',
  'word2',
  'Phrase 1',
  'word3'
);

my $handler;
open( $handler, '<', 'somefile.txt' ) or die $!;

my $stream = Stream::Reader->new( $handler );
my $result = $stream->readto( \@substrings, { Mode => 'E' } ); # Mode 'E' - at end of stream returns false

if( $result ) {
  print "Found substring '$stream->{Match}'\n";
} elsif( $stream->{Error} ) {
  die "Fatal error during reading file!\n";
} else {
  print "Nothing found..\n";
}

close($handler) or die $!;
