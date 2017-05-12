
use String::RexxParse qw(parse);

$a = 'around the rugged rocks the ragged rascal ran!';

$b=$c=$d=$e=$f=$g="";

parse $a, q~ $b . $c 'rocks' $d +5 . . $e '!' $f -3 $g +3 ~;

print "1..6\n";


if ($b eq 'around' ) { print "ok 1\n" }
else { print "not ok 1\n" }

if ($c eq 'rugged ' ) { print "ok 2\n" }
else { print "not ok 2\n" }

if ($d eq 'rocks' ) { print "ok 3\n" }
else { print "not ok 3\n" }

if ($e eq 'rascal ran' ) { print "ok 4\n" }
else { print "not ok 4\n" }

if ($f eq '!' ) { print "ok 5\n" }
else { print "not ok 5\n" }

if ($g eq 'ran' ) { print "ok 6\n" }
else { print "not ok 6\n" }


