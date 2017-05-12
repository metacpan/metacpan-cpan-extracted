
use String::RexxParse qw(parse);

$a = 'around the rugged rocks the ragged rascal ran!';

$b=$c=$d=$e=$f=$g=$minus3=$eight=$pattern="";

$minus3 = -3; $eight = 8; $pattern = 'rocks';

parse $a, q~ $b $c ($pattern) $d +($eight) $e +($minus3) $f $g ~;

print "1..6\n";


if ($b eq 'around' ) { print "ok 1\n" }
else { print "not ok 1\n" }

if ($c eq 'the rugged ' ) { print "ok 2\n" }
else { print "not ok 2\n" }

if ($d eq 'rocks th' ) { print "ok 3\n" }
else { print "not ok 3\n" }

if ($e eq 'e ragged rascal ran!' ) { print "ok 4\n" }
else { print "not ok 4\n" }

if ($f eq 'the' ) { print "ok 5\n" }
else { print "not ok 5\n" }

if ($g eq 'ragged rascal ran!' ) { print "ok 6\n" }
else { print "not ok 6\n" }


