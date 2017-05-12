# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..62\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::CP932::Correct qw(:all);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my($NG, $i, $j);
my $cnt = 1;

for($i = 0; $i <= 0xff; $i++){
  next if 1 <= $i && $i <= 0x80
    || 0xa0 <= $i && $i <= 0xdf
    || 0xfd <= $i && $i <= 0xff;

  my $t = $i ? pack('C',$i) : '';
  $NG = 0;
  for($j = 0; $j <= 0xff; $j++){
    my $c  = $t.pack('C', $j);
    my $is = is_cp932($c);
    my $cc = correct_cp932($c);
    my $co = is_corrected_cp932($c);
    $NG++ unless $is == ('' ne $cc);
    $NG++ unless $co == ($c eq $cc);
  }
  print ! $NG ? "ok" : "not ok", " ", ++$cnt, "\n";
}
