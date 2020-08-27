#!/usr/bin/perl
#-*-perl-*-

use FindBin qw( $Bin );
use lib $Bin. '/../lib';

use Test::More;
use File::Compare;

my $SCRIPTS = $Bin.'/../scripts';
my $DATA    = $Bin.'/xml';

system("$SCRIPTS/alignments/opus-merge-align $DATA/sv-de.xml $DATA/sv-en.xml > merged.xml");
is( compare( "merged.xml", "$DATA/sv-de-en.xml" ),0, "merged (sv-de + sv-en)" );
unlink('merged.xml');

system("$SCRIPTS/alignments/opus-merge-align $DATA/sv-en.xml $DATA/sv-de.xml > merged.xml");
is( compare( "merged.xml", "$DATA/sv-de-en.xml" ),0, "merged (sv-en + sv-de)" );
unlink('merged.xml');

system("$SCRIPTS/alignments/opus-merge-align $DATA/sv-de.xml $DATA/sv-de.xml > merged.xml");
is( compare( "merged.xml", "$DATA/sv-de.xml" ),0, "merged (sv-de + sv-de)" );
unlink('merged.xml');

system("$SCRIPTS/alignments/opus-merge-align $DATA/sv-de.xml $DATA/sv-en.xml $DATA/sv-de.xml > merged.xml");
is( compare( "merged.xml", "$DATA/sv-de-en.xml" ),0, "merged (sv-de + sv-en + sv-de)" );
unlink('merged.xml');

done_testing;

