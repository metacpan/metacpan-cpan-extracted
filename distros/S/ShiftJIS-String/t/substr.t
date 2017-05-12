
BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use ShiftJIS::String qw(trclosure);

local $^W = 0;
$loaded = 1;
print "ok 1\n";

#####

{
  my $printZ2H = trclosure(
    '‚O-‚X‚`-‚y‚-‚š@{|HI”“•—–ƒ„ijmnop',
    '0-9A-Za-z =+\-?!#$%&@*<>()[]{}',
  );
  my $NG;
  my $str = '01234567';
  my $zen = '0‚P‚Q‚R456‚V';
  my($i,$j);

  $NG = 0;
  for $i (-10..10){
    next if 5.004 > $] && $i < -8;
    my $s = CORE::substr($str,$i);
    my $t = ShiftJIS::String::substr($zen,$i);
    for($s,$t){$_ = 'undef' if ! defined $_;}
    ++$NG unless $s eq &$printZ2H($t);
  }
  print ! $NG ? "ok 2\n" : "not ok 2\n";

  $NG = 0;
  for $i (-10..10){
    next if 5.004 > $] && $i < -8;
    next if 5.004 <= $] && $] < 5.00402;
    for $j (undef,-10..10){
      my $s = CORE::substr($str,$i,$j);
      my $t = ShiftJIS::String::substr($zen,$i,$j);
      for($s,$t){$_ = 'undef' if ! defined $_;}
      ++$NG unless $s eq &$printZ2H($t);
    }
  }
  print ! $NG ? "ok 3\n" : "not ok 3\n";

  $NG = 0;
  for $i (-8..8){
    my $s = $str;
    my $t = $zen;
    CORE::substr($s,$i) = "RE";
    ${ ShiftJIS::String::substr(\$t,$i) } = "‚q‚d";
    ++$NG unless $s eq &$printZ2H($t);
  }
  print ! $NG ? "ok 4\n" : "not ok 4\n";

  $NG = 0;
  for $i (-8..8){
    for $j (undef,-10..10){
      my $s = $str;
      my $t = $zen;
      CORE::substr($s,$i,$j) = "RE";
      ${ ShiftJIS::String::substr(\$t,$i,$j) } = "‚q‚d";
      ++$NG unless $s eq &$printZ2H($t);
    }
  }
  print ! $NG ? "ok 5\n" : "not ok 5\n";

  $NG = 0;
  for $i (-8..8){
    last if 5.00503 > $];
    for $j (-10..10){
      my $s = $str;
      my $t = $zen;
      my $core;
      eval '$core = CORE::substr($s,$i,$j,"OK")';
      my $sjis = ShiftJIS::String::substr($t,$i,$j,"‚n‚j");
      ++$NG unless $s eq &$printZ2H($t) && $core eq &$printZ2H($sjis);
    }
  }
  print ! $NG ? "ok 6\n" : "not ok 6\n";
}

1;
__END__
