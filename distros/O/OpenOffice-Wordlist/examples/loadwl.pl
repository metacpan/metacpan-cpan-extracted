#!/usr/bin/perl

# EXAMPLE CODE AHEAD
#
# This program reads a file with ISO-8859.1 encoded words and creates
# an OpenOffice dictionary containing these words.

use strict;
use warnings;
use blib;
use OpenOffice::Wordlist;

# Language 1043 -> Dutch (Netherlands).
my $dict = OpenOffice::Wordlist->new( language => 1043 );

# Open file.
my $file = shift(@ARGV);
open( my $list, '<:encoding(iso-8859-1)', $file )
  or die("$file: $!\n");

# Sometimes the data contains leading information the needs to be skipped.
#scalar(<$list>);
#scalar(<$list>);

# Read the file and append the words.
while ( <$list> ) {
    s/[\n\r]+$//;
    $dict->append($_);
}

# Write out the new dictionary.
$dict->write("new.dic");

# Inform user.
warn( "Number of words imported from $file = ",
      scalar( @{ $dict->words } ), "\n" );
