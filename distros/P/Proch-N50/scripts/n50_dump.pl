#!/usr/bin/env perl
# Dump the data returned by Proch::N50 for any number of fastx files given as input

use 5.012;
use warnings;
use Pod::Usage;
use Term::ANSIColor qw(:constants colorvalid colored);
use Getopt::Long;
use File::Basename;
use FindBin qw($RealBin);

# The following placeholder is to be programmatically replaced with 'use lib "$RealBin/../lib"' if needed
#~loclib~
if ( -e "$RealBin/../lib/Proch/N50.pm" and -e "$RealBin/../Changes" ) {
    use lib "$RealBin/../lib";
}
use Proch::N50;
use Data::Dumper;
use File::Basename;
foreach my $file (@ARGV) {
  # Check if file exists / check if '-' supplied read STDIN
  if ( ( !-e "$file" ) and ( $file ne '-' ) ) {
      die " FATAL ERROR:\n File not found ($file).\n";
  }
  elsif ( $file eq '-' ) {

      # Set file to <STDIN>
      $file = '-';
  }
  else {
      # Open filehandle with $file
      open STDIN, '<', "$file"
        || die " FATAL ERROR:\n Unable to open file for reading ($file).\n";
  }

  my $FileStats = Proch::N50::getStats( $file, undef, 40 );
  say Dumper $FileStats;
  say $FileStats->{'Ne'};

}
