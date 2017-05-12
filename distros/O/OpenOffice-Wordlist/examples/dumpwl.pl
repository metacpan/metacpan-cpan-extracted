#!/usr/bin/perl

# EXAMPLE CODE AHEAD
#
# This program reads wan OpenOffice dictionary and prints all words.

use strict;
use warnings;
use blib;
use OpenOffice::Wordlist;

my $dict = OpenOffice::Wordlist->new->read( shift(@ARGV) );

# Make sure the output type is correctly set up.
binmode( STDOUT, ':utf8' );

# Print the words.
foreach my $word ( @{ $dict->words } ) {
    print( $word, "\n" );
}
