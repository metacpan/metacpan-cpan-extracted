#!/usr/bin/perl

use Storable;

$syl_min = 2;
$syl_max = 3;

$werd_min = 5;
$werd_max = 10;

$grammar_file = $ARGV[0];
$grammar_file = "grammar" if !$grammar_file;

my $grammar_ref = retrieve($grammar_file);
*fragments = \@{$grammar_ref};

$count = scalar(@fragments);

for($i = 0; $i < $count; $i++) {
  $locate{$fragments[$i][0]} = $i;
}

$numwerds = int(rand() * ($werd_max - $werd_min) + $werd_min);
while($werdcount < $numwerds) {
  $sentence .= getWerd() . " ";
  $werdcount++;
}
$sentence =~ s/ $//;
$sentence = ucfirst $sentence;

print "$sentence\n";

sub getWerd {
  my $syl = "_BEGIN_";
  my $werd = "";
  my $which;
  my $sylcount = 0;

  while($syl ne "_END_") {

    $which = -1;
    if($syl ne "_BEGIN_") { $werd .= $syl; }
    my $offset = $locate{$syl};
    my $count = scalar(@{$fragments[$offset][1]});
    if($sylcount > $syl_max) {
      # Time to choose an end
      $which = -1;
      for($i = 0; $i < $count; $i++) {
        if($fragments[$offset][1][$i][0] eq "_END_") {
          $which = $i;
          last;
        }
      }
    }
    if($which < 0) {
      my $freq_total;

      foreach $freq (@{$fragments[$offset][2]}) { $freq_total+= $freq; }
      do {
        my ($freq_sum, $i, $which_freq);

        $which_freq = int(rand() * $freq_total + 1);
        for($i = 0; $i < scalar(@{$fragments[$offset][2]}); $i++) {
          $freq_sum += $fragments[$offset][2][$i];
          if($freq_sum >= $which_freq) {
            $which = $i;
            last;
          }
        }
      } while(($fragments[$offset][1][$which][0] eq "_END_") and ($count > 1) and ($sylcount < $syl_min));
    }
    $syl = $fragments[$offset][1][$which][0];
    $sylcount++;
  }
  
  return($werd);
}
