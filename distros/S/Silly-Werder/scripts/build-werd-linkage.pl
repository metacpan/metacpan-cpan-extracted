#!/usr/bin/perl
#
# This script is intended to build a grammar for werder based on a syllable 
# list provided.  It reads text files fed in and attempts to dissect them 
# and builds linkages of each syllable
#

use Storable;
use POSIX qw(locale_h);
use locale;

my $locale = ($ARGV[3] or "en_US");
$ret = setlocale(LC_CTYPE, $locale);
if(!defined($ret)) {
  print STDERR "Could not load locale $locale: $!\n";
  exit;
}

my $file = $ARGV[0];
if(!$file) {
  usage();
  exit;
}

# Homecooked char set of Latin-1 alphas
$charset = "A-Za-z\xa0-\xbf\xc0-\xd6\xda-\xdd\xdf-\xf6\xf9-\xfd\xff'\\-";
$syllables = "../Werder/data/syllables";

$appears_threshhold = ($ARGV[1] or 1);
$follower_threshhold = ($ARGV[2] or 1);

sub usage() {
  print STDERR "Usage: $0 out-file [appears-threshhold [follower-threshhold [locale]]]\n";
}

sub parse($) {
  my $werd = shift;
  my $start_at = shift;
  my ($syl, $ready, $next_syl);


  if($werd eq "") {
    my $first = $werd_parts[0];
    my $last = $werd_parts[$#werd_parts];
    my $i;

    $werd_account{_BEGIN_}{$first} = 1;
    $werd_account{$last}{_END_} = 1;

    for($i = 1; $i <= $#werd_parts; $i++) {
      $werd_account{$werd_parts[$i-1]}{$werd_parts[$i]} = 1;
    }

    $variations++;
  }


  $werd =~ /^((.).?)/;
  my $first = lc($2);
  my $firsttwo = lc($1);
  # gotta remember to check for syls that are just 1 in length
  foreach $syl (@{$indexed_syllables{$first}{_}}, @{$indexed_syllables{$first}{$firsttwo}}) {
# foreach $syl (@syllables) {
    $next_syl = 0;
    if($start_at && !$ready) { $next_syl = 1; }
    if(($syl eq $start_at) || !$start_at) { $ready = 1; }
    next if $next_syl;


    if($werd =~ /^$syl(.*)$/si) {
      push @werd_parts, $syl;
      parse($1);
      return;
    }
  }


  if(scalar(@werd_parts)) {
    my $oldsyl = pop @werd_parts;
    parse($oldsyl . $werd, $oldsyl);
    return;
  }
  else {
    return;
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

#foreach $syllable (@syllables) { print "$syllable\n"; } exit;

foreach $syl (@syllables) {
  $syl =~ /^((.).?)/;
  my $first = lc($2);
  my $firsttwo = lc($1);
  if($first eq $firsttwo) { $firsttwo = "_"; }
  push @{$indexed_syllables{$first}{$firsttwo}}, $syl;
}

while(<STDIN>) {
  $line = $_;
   while($line =~ /[^$charset]*([$charset]+)[^$charset]*/sig) {
    $werd = $1;
    $werd =~ s/^['\-]*//;
    $werd =~ s/['\-]*$//;
    if($werd eq "") { next; }

    $variations = 0;
    parse($werd);
    if($variations == 0) {
      print STDERR "Couldn't parse $werd\n";
    }
    else {
      foreach $syllable (keys %werd_account) {
        foreach $follower (keys %{$werd_account{$syllable}}) {
          $account{$syllable}{$follower}++;
        }
      }
    }
    undef @werd_parts;
    undef %werd_account;
    $werd_count++;
    if($werd_count % 1000 == 0) { print STDERR "$werd_count so far\n"; }
  }
}

$fragments[0][0] = "_BEGIN_";
$locate{"_BEGIN_"} = 0;

# Go through list and remove links that appear less than appears_threshhold
foreach $syllable (keys %account) {
  foreach $follower (keys %{$account{$syllable}}) {
    if($account{$syllable}{$follower} < $appears_threshhold) {
      # just delete this link, the next parse will weed it out if theres too few links
print "deleting $syllable $follower ($account{$syllable}{$follower} appears)\n";
      delete $account{$syllable}{$follower};
    }
  }
}

# Loop over accounting and remove anything with less links than follower_threshhold
my $syls_removed = 1;
while($syls_removed) {
  $syls_removed = 0;

  foreach $syllable (keys %account) {

    $explicit_keep = 0;
    my $linkcount = scalar(keys %{$account{$syllable}});

    # check for _END_ first, so good endings dont get removed
    foreach $follower (keys %{$account{$syllable}}) {
      if($follower eq "_END_") { $explicit_keep = 1; }
    }
    if($explicit_keep) { next; }

    if($linkcount < $follower_threshhold) {

      # sub loop to remove links to this node
      foreach $prior (keys %account) {
        if($account{$prior}{$syllable}) {
          delete $account{$prior}{$syllable};
        }
      }

print "deleting $syllable ($linkcount followers)\n";
      delete $account{$syllable};
      $syls_removed = 1;
    }
  }
}

foreach $syllable (keys %account) {

  my $offset = $locate{$syllable};
  if(!defined($locate{$syllable})) {
    $syllable_count++;
    $fragments[$syllable_count][0] = $syllable;
    $offset = $syllable_count;
    $locate{$syllable} = $offset;
  }

  foreach $follower (keys %{$account{$syllable}}) {

    my $follower_offset = $locate{$follower};
    if(!$follower_offset) {
      $syllable_count++;
      $fragments[$syllable_count][0] = $follower;
      $follower_offset = $syllable_count;
      $locate{$follower} = $follower_offset;
    }

    push @{$fragments[$offset][1]}, \@{$fragments[$follower_offset]};
    push @{$fragments[$offset][2]}, $account{$syllable}{$follower};
  }
}

if(!Storable::nstore(\@fragments, $file)) {
  print STDERR "Error writing $file\n";
}
