
use String::RexxParse qw(parse);

$a = 'The quick brown fox jumped over the lazy dog.';

$b=$c=$d=$e=$f=$g="";

parse $a, q~ +3 $b +4 $c 'rocks' $d +5 0 $e $f 20 $g 30 ~;

print "1..6\n";

if ($b eq ' qui' ) { print "ok 1\n" }
else { print "not ok 1\n" }

if ($c eq 'ck brown fox jumped over the lazy dog.' ) { print "ok 2\n" }
else { print "not ok 2\n" }

if ($d eq '' ) { print "ok 3\n" }
else { print "not ok 3\n" }

if ($e eq 'The' ) { print "ok 4\n" }
else { print "not ok 4\n" }

if ($f eq 'quick brown fox ' ) { print "ok 5\n" }
else { print "not ok 5\n" }

if ($g eq 'jumped ove' ) { print "ok 6\n" }
else { print "not ok 6\n" }


