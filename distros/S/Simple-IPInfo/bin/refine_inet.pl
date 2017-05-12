#!/usr/bin/perl
use strict;
use warnings;

my ( $f, $dst_f ) = @ARGV;
$dst_f ||= "$f.refine";

open my $fh, '<', $f;
my $head = <$fh>;
my ( $old_s, $old_e, $old_d ) = $head =~ m#^(.+?),(.+?),(.*)$#;

open my $fhw, '>', $dst_f;
while ( <$fh> ) {
  chomp;
  my ( $s, $e, $d ) = m#^(\d+),(\d+),(.*)$#;
  $d //= '';
  if ( ( $old_d eq $d ) and (
          ( $old_e + 1 == $s )
              or
          ( $s>=$old_s and $s<$old_e and $e>$old_e )
      )) {
    $old_e = $e;
  }elsif( ( $old_d eq $d ) and ($s>=$old_s) and ($e<=$old_e) ){
  }
  else {
    print $fhw join( ",", $old_s, $old_e, $old_d ), "\n";
    ( $old_s, $old_e, $old_d ) = ( $s, $e, $d );
  }
}
print $fhw join( ",", $old_s, $old_e, $old_d ), "\n";
close $fhw;
close $fh;
