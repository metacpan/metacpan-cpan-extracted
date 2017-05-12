#!/usr/bin/perl
#
# This script is intended to build a grammar for werder based on a syllable list provided.
# It reads text files fed in and attempts to dissect them and builds linkages of each syllable
#

use POSIX qw(locale_h);
use locale;
setlocale("LC_CTYPE", "en_US");

# Homecooked char set of Latin-1 alphas
$charset = "A-Za-z\xa0-\xbf\xc0-\xd6\xda-\xdd\xdf-\xf6\xf9-\xfd\xff'\\-";
$syllables = "../Werder/data/syllables";

sub parse($) {
  my $werd = shift;
  my $start_at = shift;
  my ($syl, $ready, $next_syl);

  if($werd eq "") { return(1); }

  $werd =~ /^((.).?)/;
  my $first = lc($2);
  my $firsttwo = lc($1);
  # gotta remember to check for syls that are just 1 in length 
  foreach $syl (@{$indexed_syllables{$first}{$first}}, @{$indexed_syllables{$first}{$firsttwo}}) {
    $next_syl = 0;
    if($start_at && !$ready) { $next_syl = 1; }
    if($syl eq $start_at) { $ready = 1; }
    next if $next_syl;

    if($werd =~ /^$syl(.*)$/si) {
     push @werd_parts, $syl;
      my $ret = parse($1);
      return($ret) if $ret;
    }
  }

  if(scalar(@werd_parts)) {
    my $oldsyl = pop @werd_parts;
    print "* going back from $oldsyl\n" if $debug;
    my $ret = parse($oldsyl . $werd, $oldsyl);
    return($ret) if $ret;
  }
  else {
    return(0);
  }
}


# Load the syllable list
open SYLS, $syllables;
chomp(@syllables = <SYLS>);
close SYLS;

# Sort the list, but sorting longer words higher
@syllables = sort { $min = (length($a) < length($b)) ? length($a) : length($b);
          ( substr($a,0,$min) cmp substr($b,0,$min) ||
            length($b) <=> length($a) )
          } @syllables;

# foreach $syl(@syllables) { print "$syl\n"; } exit;

foreach $syl (@syllables) {
  $syl =~ /^((.).?)/;
  my $first = lc($2);
  my $firsttwo = lc($1);
  push @{$indexed_syllables{$first}{$firsttwo}}, $syl;
}

while(<>) {
  $line = $_;
  while($line =~ /[^$charset]*([$charset]+)[^$charset]*/sig) {
    $werd = $1;
    $werd =~ s/^['\-]*//;
    $werd =~ s/['\-]*$//;
    if($werd eq "") { next; }

    if(!parse($werd)) {
      print "* couldnt parse $werd\n";
    }
    else {
      my $werd_sep = join ' ',@werd_parts;
#      print "$werd_sep\n";
    }
    undef @werd_parts;
  }
}
