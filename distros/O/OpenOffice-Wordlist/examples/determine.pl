#!/usr/bin/perl

# EXAMPLE CODE AHEAD
#
# This program reads an OpenOffice dictionary and shows its contents
# (but not the words).

use strict;
use warnings;
use blib;
use OpenOffice::Wordlist;

# Create a new dict without a type. This will cause the type from the
# file read to be copied.
my $dict = OpenOffice::Wordlist->new( type => '' );

# Open file and read it.
my $file = shift(@ARGV);
$dict->read($file);

# Inform user.
warn( join (", ",
	    "Dictionary file $file, type = " . $dict->{type},
	    "language = " , $dict->{language},
	    "neg = " . ($dict->{neg}||0),
	    "number of words = " . scalar( @{ $dict->words } ),
	    ), "\n" );
