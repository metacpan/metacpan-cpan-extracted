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
  #print "$old_s, $old_e, $old_d => $s, $e, $d\n" if($d==15169);
  if ( ( $old_d eq $d ) and (
          ( $s<=$old_e+1 )
      )) {
      $old_e = $old_e>$e ? $old_e : $e;
  }elsif( ($old_d eq $d) and ($s>=$old_s) and ($e<=$old_e)){
          #not change
  }elsif(($old_d ne $d) and ($old_e>$s)){
    print $fhw join( ",", $old_s, $s-1, $old_d ), "\n";
    if($e>$old_e){
        ( $old_s, $old_e, $old_d ) = ( $s, $e, $d );
    }else{
        print $fhw join( ",", $s, $e, $d ), "\n";
        ( $old_s, $old_e, $old_d ) = ( $e+1, $old_e, $old_d );
    }
  }
  else {
    print $fhw join( ",", $old_s, $old_e, $old_d ), "\n";
    ( $old_s, $old_e, $old_d ) = ( $s, $e, $d );
  }
}
print $fhw join( ",", $old_s, $old_e, $old_d ), "\n";
close $fhw;
close $fh;
